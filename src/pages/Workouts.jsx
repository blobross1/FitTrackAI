import React, { useState, useRef, useEffect } from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Input } from "@/components/ui/input";
import { Check, Trophy } from 'lucide-react';

const calculate1RM = (weight, reps) => {
    if (!weight || !reps) return 0;
    return Math.round(weight * (1 + reps / 30));
};

// Strength standards: [Beginner, Novice, Intermediate, Advanced, Elite]
const strengthStandards = {
    "Incline Dumbbell Press": [22, 30, 40, 52, 66],
    "Chest Machine": [38, 62, 92, 130, 174],
    "Pec Deck": [38, 60, 89, 123, 160],
    "Neutral Grip Pull-up": [1, 7, 15, 25, 36],
    "Neutral Grip Pull-up (Set 2)": [1, 7, 15, 25, 36],
    "Diverging Seated Row": [44, 69, 103, 143, 187],
    "Tricep Overhead": [6, 12, 21, 33, 47],
    "Lying Bicep Curls": [8, 14, 24, 38, 52],
    "Lateral Raises": [4, 10, 16, 26, 36],
};

const levelNames = ["Beginner", "Novice", "Intermediate", "Advanced", "Elite"];
const levelColors = {
    "Beginner": "text-gray-400",
    "Novice": "text-green-500",
    "Intermediate": "text-blue-500",
    "Advanced": "text-purple-500",
    "Elite": "text-yellow-500"
};

const getStrengthLevel = (exerciseName, oneRM) => {
    const standards = strengthStandards[exerciseName];
    if (!standards || !oneRM) return { level: "Beginner", nextLevel: "Novice", needed: standards?.[0] || 0 };
    
    let levelIndex = 0;
    for (let i = standards.length - 1; i >= 0; i--) {
        if (oneRM >= standards[i]) {
            levelIndex = i;
            break;
        }
    }
    
    const level = levelNames[levelIndex];
    const nextLevelIndex = Math.min(levelIndex + 1, levelNames.length - 1);
    const nextLevel = levelNames[nextLevelIndex];
    const needed = levelIndex < standards.length - 1 ? standards[nextLevelIndex] : null;
    
    return { level, nextLevel, needed };
};

const defaultExercises = [
    { name: "Incline Dumbbell Press", category: "Push", last_weight: 26, last_reps: 12, order: 1 },
    { name: "Chest Machine", category: "Push", last_weight: 73, last_reps: 9, order: 2 },
    { name: "Pec Deck", category: "Push", last_weight: 79, last_reps: 10, order: 3 },
    { name: "Neutral Grip Pull-up", category: "Pull", last_weight: null, last_reps: 17, is_bodyweight: true, order: 4 },
    { name: "Diverging Seated Row", category: "Pull", last_weight: 59, last_reps: 12, order: 5 },
    { name: "Neutral Grip Pull-up (Set 2)", category: "Pull", last_weight: null, last_reps: null, is_bodyweight: true, order: 6 },
    { name: "Tricep Overhead", category: "Push", last_weight: 12, last_reps: 14, order: 7 },
    { name: "Lying Bicep Curls", category: "Pull", last_weight: 12, last_reps: 9, order: 8 },
    { name: "Lateral Raises", category: "Push", last_weight: 12, last_reps: 4, order: 9 },
];

export default function Workouts() {
    const queryClient = useQueryClient();
    const [completedIds, setCompletedIds] = useState(new Set());
    const [completedData, setCompletedData] = useState({});
    const [exerciseInputs, setExerciseInputs] = useState({});
    const [prFlash, setPrFlash] = useState(null);
    const inputRefs = useRef({});
    
    const { data: exercises = [], isLoading } = useQuery({
        queryKey: ['exercises'],
        queryFn: async () => {
            const existing = await base44.entities.Exercise.list('order');
            const filtered = existing.filter(ex => !ex.is_timed);
            if (filtered.length === 0) {
                await base44.entities.Exercise.bulkCreate(defaultExercises);
                return await base44.entities.Exercise.list('order');
            }
            return filtered;
        }
    });

    const { data: recentLogs = [] } = useQuery({
        queryKey: ['exerciseLogs'],
        queryFn: () => base44.entities.ExerciseLog.list('-date', 200)
    });

    useEffect(() => {
        if (exercises.length > 0) {
            const inputs = {};
            exercises.forEach(ex => {
                inputs[ex.id] = {
                    weight: ex.last_weight || '',
                    reps: ex.last_reps || ''
                };
            });
            setExerciseInputs(inputs);
        }
    }, [exercises]);

    const getPreviousBestRM = (exerciseName) => {
        const logs = recentLogs.filter(l => l.exercise_name === exerciseName && l.one_rm);
        if (logs.length === 0) return null;
        return Math.max(...logs.map(l => l.one_rm));
    };

    const updateInput = (id, field, value) => {
        setExerciseInputs(prev => ({
            ...prev,
            [id]: {
                ...prev[id],
                [field]: value
            }
        }));
    };

    const handleSubmit = async (exercise, index) => {
        const input = exerciseInputs[exercise.id];
        if (!input) return;
        
        const weight = parseFloat(input.weight) || 0;
        const reps = parseInt(input.reps) || 0;
        
        const oneRM = exercise.is_bodyweight ? reps : calculate1RM(weight, reps);
        const previousBest = getPreviousBestRM(exercise.name);
        const isNewPR = previousBest && oneRM > previousBest;
        
        // Show PR flash
        if (isNewPR) {
            setPrFlash({ name: exercise.name, oneRM });
            setTimeout(() => setPrFlash(null), 2000);
        }
        
        // Log the exercise
        await base44.entities.ExerciseLog.create({
            exercise_id: exercise.id,
            exercise_name: exercise.name,
            weight: weight || null,
            reps: reps,
            one_rm: oneRM,
            date: new Date().toISOString().split('T')[0]
        });
        
        // Update exercise with last values
        await base44.entities.Exercise.update(exercise.id, {
            last_weight: weight || exercise.last_weight,
            last_reps: reps || exercise.last_reps,
            best_one_rm: oneRM && (!exercise.best_one_rm || oneRM > exercise.best_one_rm) 
                ? oneRM 
                : exercise.best_one_rm
        });
        
        // Store completed data for display
        setCompletedData(prev => ({
            ...prev,
            [exercise.id]: { oneRM, isNewPR }
        }));
        
        // Mark as completed
        setCompletedIds(prev => new Set([...prev, exercise.id]));
        
        // Focus next exercise
        const nextExercise = exercises[index + 1];
        if (nextExercise && inputRefs.current[nextExercise.id]) {
            inputRefs.current[nextExercise.id].focus();
        }
        
        queryClient.invalidateQueries({ queryKey: ['exerciseLogs'] });
    };

    const handleKeyDown = (e, exercise, index) => {
        if (e.key === 'Enter') {
            e.preventDefault();
            handleSubmit(exercise, index);
        }
    };

    const categoryColor = {
        Push: 'bg-orange-500',
        Pull: 'bg-blue-500',
        Legs: 'bg-green-500',
        Core: 'bg-yellow-500',
        Other: 'bg-gray-500'
    };

    if (isLoading) {
        return (
            <div className="min-h-screen bg-black flex items-center justify-center">
                <div className="text-white">Loading...</div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-black pb-24">
            {/* PR Flash Overlay */}
            {prFlash && (
                <div className="fixed inset-0 bg-black/90 z-50 flex items-center justify-center animate-in fade-in duration-200">
                    <div className="text-center">
                        <Trophy className="h-16 w-16 text-yellow-500 mx-auto mb-4 animate-bounce" />
                        <p className="text-yellow-500 text-xl font-bold mb-2">NEW PR!</p>
                        <p className="text-white text-3xl font-bold">{prFlash.name}</p>
                        <p className="text-4xl font-bold text-yellow-500 mt-2">{prFlash.oneRM} kg</p>
                    </div>
                </div>
            )}

            <div className="p-6">
                <h1 className="text-3xl font-bold text-white mb-2">Workout</h1>
                <p className="text-gray-500 mb-6">Log your sets</p>
                
                <div className="space-y-3">
                    {exercises.map((exercise, index) => {
                        const isCompleted = completedIds.has(exercise.id);
                        const input = exerciseInputs[exercise.id] || { weight: '', reps: '' };
                        const completed = completedData[exercise.id];
                        
                        const currentOneRM = isCompleted && completed 
                            ? completed.oneRM 
                            : (!exercise.is_bodyweight && input.weight && input.reps 
                                ? calculate1RM(parseFloat(input.weight), parseInt(input.reps))
                                : (exercise.is_bodyweight && input.reps ? parseInt(input.reps) : null));
                        
                        const strengthInfo = getStrengthLevel(exercise.name, currentOneRM);
                        const hasStandards = strengthStandards[exercise.name];
                        
                        return (
                            <div 
                                key={exercise.id}
                                className={`rounded-xl p-4 transition-all ${
                                    isCompleted 
                                        ? 'bg-gray-900/50' 
                                        : 'bg-gray-900'
                                }`}
                            >
                                <div className="flex items-center gap-3 mb-2">
                                    <div className={`w-2 h-2 rounded-full ${categoryColor[exercise.category] || 'bg-gray-500'}`} />
                                    <span className={`font-medium flex-1 ${isCompleted ? 'text-gray-400' : 'text-white'}`}>
                                        {exercise.name}
                                    </span>
                                    {isCompleted && <Check className="h-5 w-5 text-green-500" />}
                                </div>
                                
                                {/* Strength level info */}
                                {hasStandards && (
                                    <div className="flex items-center justify-between mb-3 text-xs">
                                        <span className={levelColors[strengthInfo.level]}>
                                            {strengthInfo.level}
                                        </span>
                                        {strengthInfo.needed && strengthInfo.level !== "Elite" && (
                                            <span className="text-gray-500">
                                                Next: {strengthInfo.nextLevel} @ {strengthInfo.needed}kg
                                            </span>
                                        )}
                                    </div>
                                )}
                                
                                <div className="flex gap-3 items-center">
                                    {!exercise.is_bodyweight && (
                                        <div className="flex-1">
                                            <Input
                                                ref={el => {
                                                    if (!exercise.is_bodyweight) {
                                                        inputRefs.current[exercise.id] = el;
                                                    }
                                                }}
                                                type="number"
                                                inputMode="decimal"
                                                value={input.weight}
                                                onChange={(e) => updateInput(exercise.id, 'weight', e.target.value)}
                                                onKeyDown={(e) => handleKeyDown(e, exercise, index)}
                                                disabled={isCompleted}
                                                placeholder="kg"
                                                className="h-12 bg-gray-800 border-gray-700 text-white text-center rounded-xl disabled:opacity-50"
                                            />
                                        </div>
                                    )}
                                    <div className="flex-1">
                                        <Input
                                            ref={el => {
                                                if (exercise.is_bodyweight) {
                                                    inputRefs.current[exercise.id] = el;
                                                }
                                            }}
                                            type="number"
                                            inputMode="numeric"
                                            value={input.reps}
                                            onChange={(e) => updateInput(exercise.id, 'reps', e.target.value)}
                                            onKeyDown={(e) => handleKeyDown(e, exercise, index)}
                                            disabled={isCompleted}
                                            placeholder="reps"
                                            className="h-12 bg-gray-800 border-gray-700 text-white text-center rounded-xl disabled:opacity-50"
                                        />
                                    </div>
                                    
                                    {/* 1RM display - always visible when available */}
                                    <div className="w-20 text-right">
                                        {currentOneRM && (
                                            <div>
                                                <span className={`text-sm font-bold ${
                                                    isCompleted && completed?.isNewPR 
                                                        ? 'text-yellow-500' 
                                                        : 'text-orange-500'
                                                }`}>
                                                    {currentOneRM}kg
                                                </span>
                                                {isCompleted && completed?.isNewPR && (
                                                    <span className="text-yellow-500 text-xs block">PR!</span>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
                
                {completedIds.size === exercises.length && exercises.length > 0 && (
                    <div className="mt-8 text-center">
                        <p className="text-2xl font-bold text-white mb-2">Workout Complete! 💪</p>
                        <button 
                            onClick={() => {
                                setCompletedIds(new Set());
                                setCompletedData({});
                            }}
                            className="text-orange-500 font-medium"
                        >
                            Reset Workout
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
}