import React, { useState, useRef } from 'react';
import { base44 } from '@/api/base44Client';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Camera, Upload, Loader2 } from 'lucide-react';
import { buildBodyFatAnalysisPrompt, normalizeBodyFatEstimate } from '@/utils/bodyFat';
import { BODY_FAT_LLM_MODEL } from '@/lib/llmConfig';

export default function Progress() {
    const queryClient = useQueryClient();
    const fileInputRef = useRef(null);
    const cameraInputRef = useRef(null);
    
    const [preview, setPreview] = useState(null);
    const [file, setFile] = useState(null);
    const [weight, setWeight] = useState('');
    const [isScanning, setIsScanning] = useState(false);
    const [scanProgress, setScanProgress] = useState(0);
    const [scanText, setScanText] = useState('');
    const [result, setResult] = useState(null);
    
    const { data: photos = [] } = useQuery({
        queryKey: ['progressPhotos'],
        queryFn: () => base44.entities.ProgressPhoto.list('-created_date')
    });

    const lastPhoto = photos[0];

    const handleFileSelect = (e) => {
        const selectedFile = e.target.files[0];
        if (selectedFile) {
            setFile(selectedFile);
            setPreview(URL.createObjectURL(selectedFile));
            setResult(null);
        }
    };

    const handleAnalyze = async () => {
        if (!file) return;
        
        setIsScanning(true);
        setScanProgress(0);
        setResult(null);
        
        const scanTexts = [
            'Analyzing physique...',
            'Measuring proportions...',
            'Estimating body composition...',
            'Calculating fat distribution...',
            'Finalizing estimate...'
        ];
        
        let progress = 0;
        const interval = setInterval(() => {
            progress += 2;
            setScanProgress(Math.min(progress, 95));
            setScanText(scanTexts[Math.floor(progress / 20)] || scanTexts[scanTexts.length - 1]);
        }, 100);
        
        const { file_url } = await base44.integrations.Core.UploadFile({ file });
        
        const analysis = await base44.integrations.Core.InvokeLLM({
            prompt: buildBodyFatAnalysisPrompt(weight ? parseFloat(weight) : null),
            model: BODY_FAT_LLM_MODEL,
            file_urls: [file_url],
            response_json_schema: {
                type: "object",
                properties: {
                    body_fat_low: { type: "number" },
                    body_fat_high: { type: "number" },
                    feedback: { type: "string" }
                }
            }
        });
        
        clearInterval(interval);
        setScanProgress(100);
        
        const body_fat_percent = normalizeBodyFatEstimate(
            analysis.body_fat_low,
            analysis.body_fat_high
        );

        const photoData = {
            photo_url: file_url,
            ai_body_fat_low: analysis.body_fat_low,
            ai_body_fat_high: analysis.body_fat_high,
            body_fat_percent,
            weight: weight ? parseFloat(weight) : null,
            ai_feedback: analysis.feedback
        };
        
        await base44.entities.ProgressPhoto.create(photoData);
        
        if (weight) {
            await base44.entities.WeightLog.create({
                weight: parseFloat(weight),
                date: new Date().toISOString().split('T')[0]
            });
        }
        
        setResult(photoData);
        setIsScanning(false);
        queryClient.invalidateQueries({ queryKey: ['progressPhotos'] });
    };

    const resetPhoto = () => {
        setPreview(null);
        setFile(null);
        setResult(null);
        setWeight('');
    };

    const getChange = () => {
        if (!result || !lastPhoto) return null;
        const currentAvg = result.body_fat_percent;
        const lastAvg = lastPhoto.body_fat_percent
            ?? (lastPhoto.body_fat_low != null && lastPhoto.body_fat_high != null
                ? (lastPhoto.body_fat_low + lastPhoto.body_fat_high) / 2
                : null);
        if (lastAvg == null) return null;
        const diff = currentAvg - lastAvg;
        if (Math.abs(diff) < 0.5) return null;
        return diff;
    };

    const change = getChange();

    return (
        <div className="min-h-screen bg-black pb-24">
            <div className="p-6">
                <h1 className="text-3xl font-bold text-white mb-2">Body Fat %</h1>
                <p className="text-gray-500 mb-6">Upload a photo for analysis</p>
                
                {/* Photo display area - fixed size */}
                <div className="w-full max-h-[42dvh] aspect-[3/4] bg-gray-900 rounded-2xl overflow-hidden mb-6 relative mx-auto max-w-full">
                    {preview ? (
                        <>
                            <img src={preview} alt="Preview" className="absolute inset-0 w-full h-full object-cover" />
                            <button 
                                onClick={resetPhoto}
                                className="absolute top-3 right-3 p-2 bg-black/50 rounded-full text-white hover:bg-black/70"
                            >
                                ×
                            </button>
                            
                            {/* Scanning overlay */}
                            {isScanning && (
                                <div className="absolute inset-0 pointer-events-none">
                                    <div 
                                        className="absolute left-0 right-0 h-1 bg-gradient-to-r from-transparent via-orange-500 to-transparent"
                                        style={{ 
                                            top: `${scanProgress}%`,
                                            boxShadow: '0 0 20px 10px rgba(249, 115, 22, 0.3)',
                                            transition: 'top 0.1s linear'
                                        }}
                                    />
                                    <div className="absolute top-4 left-4 w-12 h-12 border-t-2 border-l-2 border-orange-500" />
                                    <div className="absolute top-4 right-4 w-12 h-12 border-t-2 border-r-2 border-orange-500" />
                                    <div className="absolute bottom-4 left-4 w-12 h-12 border-b-2 border-l-2 border-orange-500" />
                                    <div className="absolute bottom-4 right-4 w-12 h-12 border-b-2 border-r-2 border-orange-500" />
                                </div>
                            )}
                        </>
                    ) : (
                        <div className="w-full h-full flex flex-col items-center justify-center gap-6 p-6">
                            <div className="flex gap-4">
                                <button
                                    onClick={() => cameraInputRef.current?.click()}
                                    className="flex flex-col items-center gap-2 p-6 bg-gray-800 rounded-2xl active:bg-gray-700"
                                >
                                    <Camera className="h-10 w-10 text-orange-500" />
                                    <span className="text-white font-medium">Take Photo</span>
                                </button>
                                <button
                                    onClick={() => fileInputRef.current?.click()}
                                    className="flex flex-col items-center gap-2 p-6 bg-gray-800 rounded-2xl active:bg-gray-700"
                                >
                                    <Upload className="h-10 w-10 text-orange-500" />
                                    <span className="text-white font-medium">Upload</span>
                                </button>
                            </div>
                        </div>
                    )}
                </div>
                
                <input
                    ref={cameraInputRef}
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={handleFileSelect}
                    className="hidden"
                />
                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileSelect}
                    className="hidden"
                />

                {/* Scanning status */}
                {isScanning && (
                    <div className="mb-6">
                        <div className="flex items-center justify-center gap-3 mb-3">
                            <Loader2 className="h-5 w-5 animate-spin text-orange-500" />
                            <span className="text-white font-medium">{scanText}</span>
                        </div>
                        <div className="h-2 bg-gray-800 rounded-full overflow-hidden">
                            <div 
                                className="h-full bg-gradient-to-r from-orange-500 to-red-500 transition-all duration-100"
                                style={{ width: `${scanProgress}%` }}
                            />
                        </div>
                    </div>
                )}

                {/* Result display */}
                {result && !isScanning && (
                    <div className="mb-6 text-center animate-in fade-in duration-500">
                        {result.ai_body_fat_low != null && result.ai_body_fat_high != null && (
                            <div className="mb-4">
                                <p className="text-gray-500 text-xs mb-1">AI estimate (raw)</p>
                                <p className="text-xl font-semibold text-gray-400">
                                    {result.ai_body_fat_low}–{result.ai_body_fat_high}%
                                </p>
                            </div>
                        )}
                        <p className="text-gray-400 text-sm mb-2">Body Fat %</p>
                        <div className="flex items-center justify-center gap-2">
                            <span className="text-5xl font-bold text-white">{result.body_fat_percent}</span>
                            <span className="text-2xl text-gray-500">%</span>
                        </div>
                        {change !== null && (
                            <p className={`mt-2 text-lg font-medium ${change < 0 ? 'text-green-500' : 'text-red-400'}`}>
                                {change < 0 ? '↓' : '↑'} {Math.abs(change).toFixed(1)}% from last
                            </p>
                        )}
                        {result.ai_feedback && (
                            <div className="bg-gray-900 rounded-2xl p-4 mt-4 text-left">
                                <p className="text-gray-300 text-sm leading-relaxed">{result.ai_feedback}</p>
                            </div>
                        )}
                    </div>
                )}

                {/* Options when photo selected but not yet analyzed */}
                {preview && !result && !isScanning && (
                    <div className="space-y-4">
                        <div>
                            <Label className="text-gray-400 text-sm mb-2 block">Weight (optional)</Label>
                            <div className="relative">
                                <Input
                                    type="number"
                                    value={weight}
                                    onChange={(e) => setWeight(e.target.value)}
                                    placeholder="Enter weight"
                                    className="h-14 bg-gray-900 border-gray-800 text-white text-lg rounded-xl pr-12"
                                />
                                <span className="absolute right-4 top-1/2 -translate-y-1/2 text-gray-500">kg</span>
                            </div>
                        </div>
                        
                        
                        <Button
                            onClick={handleAnalyze}
                            className="w-full h-14 bg-gradient-to-r from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white text-lg font-semibold rounded-xl"
                        >
                            Analyze Photo
                        </Button>
                    </div>
                )}

                {/* Take another photo button after result */}
                {result && !isScanning && (
                    <Button
                        onClick={resetPhoto}
                        className="w-full h-14 bg-gray-900 hover:bg-gray-800 text-white text-lg font-semibold rounded-xl"
                    >
                        Take Another Photo
                    </Button>
                )}

                {/* Recent photos reel */}
                {photos.length > 0 && (
                    <div className="mt-8">
                        <h2 className="text-gray-400 text-sm font-medium mb-3">Previous Photos</h2>
                        <div className="flex gap-3 overflow-x-auto pb-2 -mx-6 px-6">
                            {photos.map(photo => (
                                <div key={photo.id} className="flex-shrink-0 w-24">
                                    <div className="w-24 h-32 rounded-xl overflow-hidden bg-gray-900">
                                        <img src={photo.photo_url} alt="" className="w-full h-full object-cover" />
                                    </div>
                                    <p className="text-center text-white text-sm font-medium mt-2">
                                        {photo.body_fat_percent ?? ((photo.body_fat_low + photo.body_fat_high) / 2).toFixed(1)}%
                                    </p>
                                    {photo.weight && (
                                        <p className="text-center text-gray-500 text-xs">
                                            {photo.weight} kg
                                        </p>
                                    )}
                                </div>
                            ))}
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
}