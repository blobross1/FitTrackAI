import React from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery } from '@tanstack/react-query';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend } from 'recharts';
import { format } from 'date-fns';
import { Scale, Percent, Dumbbell } from 'lucide-react';

export default function Analytics() {
    const { data: photos = [] } = useQuery({
        queryKey: ['progressPhotos'],
        queryFn: () => base44.entities.ProgressPhoto.list('-created_date')
    });
    
    const { data: weightLogs = [] } = useQuery({
        queryKey: ['weightLogs'],
        queryFn: () => base44.entities.WeightLog.list('-date')
    });
    
    const { data: exerciseLogs = [] } = useQuery({
        queryKey: ['exerciseLogs'],
        queryFn: () => base44.entities.ExerciseLog.list('-date')
    });

    // Weight data
    const weightData = weightLogs
        .sort((a, b) => new Date(a.date) - new Date(b.date))
        .map(log => ({
            date: format(new Date(log.date), 'MMM d'),
            weight: log.weight
        }));

    // Body fat data (using midpoint of range)
    const bodyFatData = photos
        .filter(p => p.body_fat_percent != null || (p.body_fat_low && p.body_fat_high))
        .sort((a, b) => new Date(a.created_date) - new Date(b.created_date))
        .map(photo => ({
            date: format(new Date(photo.created_date), 'MMM d'),
            bodyFat: photo.body_fat_percent ?? (photo.body_fat_low + photo.body_fat_high) / 2,
        }));

    // 1RM data by exercise
    const exerciseMap = {};
    exerciseLogs
        .filter(log => log.one_rm)
        .sort((a, b) => new Date(a.date) - new Date(b.date))
        .forEach(log => {
            const dateKey = format(new Date(log.date), 'MMM d');
            if (!exerciseMap[log.exercise_name]) {
                exerciseMap[log.exercise_name] = [];
            }
            exerciseMap[log.exercise_name].push({
                date: dateKey,
                oneRM: log.one_rm
            });
        });

    const exercises = Object.keys(exerciseMap);
    const allDates = [...new Set(Object.values(exerciseMap).flatMap(arr => arr.map(d => d.date)))];
    const oneRMData = allDates.map(date => {
        const point = { date };
        exercises.forEach(ex => {
            const entry = exerciseMap[ex].find(e => e.date === date);
            if (entry) point[ex] = entry.oneRM;
        });
        return point;
    });

    const colors = ['#f97316', '#3b82f6', '#22c55e', '#a855f7', '#ec4899', '#06b6d4'];

    return (
        <div className="min-h-screen bg-black pb-24">
            <div className="p-6">
                <h1 className="text-3xl font-bold text-white mb-2">Analytics</h1>
                <p className="text-gray-500 mb-8">Track your progress over time</p>
                
                <div className="space-y-6">
                    {/* Weight Chart */}
                    <Card className="bg-gray-900 border-gray-800">
                        <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-3 text-lg font-semibold text-white">
                                <div className="p-2 bg-blue-500/20 rounded-lg">
                                    <Scale className="h-4 w-4 text-blue-500" />
                                </div>
                                Weight (kg)
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            {weightData.length > 0 ? (
                                <ResponsiveContainer width="100%" height={200}>
                                    <LineChart data={weightData}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                                        <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#9ca3af' }} stroke="#4b5563" />
                                        <YAxis tick={{ fontSize: 10, fill: '#9ca3af' }} stroke="#4b5563" domain={['dataMin - 2', 'dataMax + 2']} />
                                        <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8 }} />
                                        <Line type="monotone" dataKey="weight" stroke="#3b82f6" strokeWidth={2} dot={{ fill: '#3b82f6' }} />
                                    </LineChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="h-32 flex items-center justify-center text-gray-600">No data yet</div>
                            )}
                        </CardContent>
                    </Card>

                    {/* Body Fat Chart */}
                    <Card className="bg-gray-900 border-gray-800">
                        <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-3 text-lg font-semibold text-white">
                                <div className="p-2 bg-red-500/20 rounded-lg">
                                    <Percent className="h-4 w-4 text-red-500" />
                                </div>
                                Body Fat %
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            {bodyFatData.length > 0 ? (
                                <ResponsiveContainer width="100%" height={200}>
                                    <LineChart data={bodyFatData}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                                        <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#9ca3af' }} stroke="#4b5563" />
                                        <YAxis tick={{ fontSize: 10, fill: '#9ca3af' }} stroke="#4b5563" domain={['dataMin - 2', 'dataMax + 2']} />
                                        <Tooltip 
                                            contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8 }}
                                            formatter={(value, name) => {
                                                if (name === 'bodyFat') return [`${value.toFixed(1)}%`, 'Avg'];
                                                return [value, name];
                                            }}
                                        />
                                        <Line type="monotone" dataKey="bodyFat" stroke="#ef4444" strokeWidth={2} dot={{ fill: '#ef4444' }} />
                                    </LineChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="h-32 flex items-center justify-center text-gray-600">No data yet</div>
                            )}
                        </CardContent>
                    </Card>

                    {/* 1RM Chart */}
                    <Card className="bg-gray-900 border-gray-800">
                        <CardHeader className="pb-2">
                            <CardTitle className="flex items-center gap-3 text-lg font-semibold text-white">
                                <div className="p-2 bg-orange-500/20 rounded-lg">
                                    <Dumbbell className="h-4 w-4 text-orange-500" />
                                </div>
                                Estimated 1RM (kg)
                            </CardTitle>
                        </CardHeader>
                        <CardContent>
                            {oneRMData.length > 0 ? (
                                <ResponsiveContainer width="100%" height={300}>
                                    <LineChart data={oneRMData}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                                        <XAxis dataKey="date" tick={{ fontSize: 10, fill: '#9ca3af' }} stroke="#4b5563" />
                                        <YAxis tick={{ fontSize: 10, fill: '#9ca3af' }} stroke="#4b5563" />
                                        <Tooltip contentStyle={{ backgroundColor: '#1f2937', border: 'none', borderRadius: 8 }} />
                                        <Legend wrapperStyle={{ fontSize: 10 }} />
                                        {exercises.map((ex, i) => (
                                            <Line 
                                                key={ex}
                                                type="monotone" 
                                                dataKey={ex} 
                                                stroke={colors[i % colors.length]} 
                                                strokeWidth={2}
                                                dot={{ fill: colors[i % colors.length] }}
                                                connectNulls
                                            />
                                        ))}
                                    </LineChart>
                                </ResponsiveContainer>
                            ) : (
                                <div className="h-32 flex items-center justify-center text-gray-600">No data yet</div>
                            )}
                        </CardContent>
                    </Card>
                </div>
            </div>
        </div>
    );
}