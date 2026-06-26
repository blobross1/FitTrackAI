import React from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from './utils';
import { Camera, Dumbbell, BarChart3 } from 'lucide-react';

export default function Layout({ children, currentPageName }) {
    const navItems = [
        { name: 'Weight %', icon: Camera, page: 'Progress' },
        { name: 'Workout', icon: Dumbbell, page: 'Workouts' },
        { name: 'Analytics', icon: BarChart3, page: 'Analytics' },
    ];

    return (
        <div className="min-h-screen bg-black">
            {children}
            
            <nav className="fixed bottom-0 left-0 right-0 bg-gray-900/95 backdrop-blur-lg border-t border-gray-800 px-6 py-2 z-50" style={{ paddingBottom: 'env(safe-area-inset-bottom, 8px)' }}>
                    <div className="max-w-md mx-auto flex justify-around">
                        {navItems.map(({ name, icon: Icon, page }) => {
                            const isActive = currentPageName === page;
                            return (
                                <Link
                                    key={page}
                                    to={createPageUrl(page)}
                                    className={`flex flex-col items-center py-2 px-6 rounded-xl transition-all ${
                                        isActive 
                                            ? 'text-orange-500' 
                                            : 'text-gray-500 active:text-gray-400'
                                    }`}
                                >
                                    <Icon className={`h-6 w-6 ${isActive ? 'stroke-[2.5]' : ''}`} />
                                    <span className={`text-xs mt-1 font-medium`}>
                                        {name}
                                    </span>
                                </Link>
                            );
                        })}
                    </div>
                </nav>
        </div>
    );
}