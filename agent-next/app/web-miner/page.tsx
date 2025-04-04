'use client';

import { useState, useEffect } from 'react';
import { FileUploader } from '../../components/web-miner/FileUploader';
import DataFieldSelector from '../../components/DataFieldSelector';
import OperatorSelector from '../../components/OperatorSelector';
import AlphaGenerator from '../../components/AlphaGenerator';
import { authenticateWorldQuant, getStoredCredentials, clearStoredCredentials } from '../../lib/auth';
import { FloatingDock } from '../../components/ui/floating-dock';
import { 
  IconHome, 
  IconChartBar, 
  IconBrain, 
  IconSettings, 
  IconUser,
  IconSpider
} from '@tabler/icons-react';
import { useRouter } from 'next/navigation';

export default function WebMinerPage() {
  const [selectedFields, setSelectedFields] = useState<string[]>([]);
  const [selectedOperators, setSelectedOperators] = useState<string[]>([]);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [uploadedFile, setUploadedFile] = useState<File | null>(null);
  const router = useRouter();

  // Check if user is already authenticated
  useEffect(() => {
    const credentials = getStoredCredentials();
    if (credentials) {
      setIsAuthenticated(true);
      setUsername(credentials.username);
    } else {
      // Redirect to login page if not authenticated
      router.push('/login');
    }
  }, [router]);

  const handleLogin = async (username: string, password: string) => {
    try {
      await authenticateWorldQuant({ username, password });
      setIsAuthenticated(true);
      setUsername(username);
      setError(null);
    } catch (error) {
      console.error('Authentication error:', error);
      setError(error instanceof Error ? error.message : 'Authentication failed');
    }
  };

  const handleLogout = () => {
    clearStoredCredentials();
    setIsAuthenticated(false);
    setUsername(null);
    router.push('/login');
  };

  const handleFileUploaded = (file: File) => {
    setUploadedFile(file);
    console.log('File uploaded:', file.name);
  };

  // Define dock items for navigation
  const dockItems = [
    { title: 'Home', icon: <IconHome className="h-5 w-5" />, href: '/' },
    { title: 'Web Crawler', icon: <IconSpider className="h-5 w-5" />, href: '/web-miner' },
    { title: 'Dashboard', icon: <IconChartBar className="h-5 w-5" />, href: '/dashboard' },
    { title: 'Brain', icon: <IconBrain className="h-5 w-5" />, href: '/brain' },
    { title: 'Settings', icon: <IconSettings className="h-5 w-5" />, href: '/settings' },
    { title: 'Profile', icon: <IconUser className="h-5 w-5" />, href: '/profile' },
  ];

  // Show loading state while checking authentication
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-gray-900 text-white flex items-center justify-center p-4">
        <div className="w-full max-w-md">
          <div className="backdrop-blur-md bg-white/10 p-6 rounded-xl border border-white/20">
            <div className="flex flex-col items-center justify-center">
              <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mb-4"></div>
              <p className="text-blue-200">Redirecting to login page...</p>
            </div>
          </div>
        </div>
        <FloatingDock items={dockItems} />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-900 to-gray-900 text-white p-4 md:p-8">
      <div className="max-w-7xl mx-auto space-y-8">
        {/* Header */}
        <div className="backdrop-blur-md bg-white/10 p-6 rounded-xl border border-white/20">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                Web Crawler
              </h1>
              <p className="text-blue-200 mt-2">
                Upload research papers and generate alpha ideas using WorldQuant data
              </p>
            </div>
            
            <div className="flex items-center gap-4">
              <div className="text-right">
                <p className="text-sm text-blue-200">Logged in as</p>
                <p className="font-medium">{username}</p>
              </div>
              <button
                onClick={handleLogout}
                className="p-2 rounded-lg bg-white/10 hover:bg-white/20 transition-colors"
                title="Logout"
              >
                <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M3 3a1 1 0 00-1 1v12a1 1 0 001 1h12a1 1 0 001-1V7.414l-5-5H3zm7 8a1 1 0 10-2 0v3a1 1 0 102 0v-3z" clipRule="evenodd" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Left Column */}
          <div className="space-y-8">
            <FileUploader onFileUploaded={handleFileUploaded} />
            <DataFieldSelector onFieldsSelected={setSelectedFields} />
            <OperatorSelector onOperatorsSelected={setSelectedOperators} />
          </div>
          
          {/* Right Column */}
          <div>
            <AlphaGenerator
              selectedFields={selectedFields}
              selectedOperators={selectedOperators}
            />
          </div>
        </div>
      </div>
      
      {/* Floating Dock */}
      <FloatingDock items={dockItems} />
    </div>
  );
} 