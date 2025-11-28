import { createContext, useContext, useState, useEffect } from "react";
import { getBackendUrl, configPromise } from "../utils/config.js";

export const AppContext = createContext();

export const useAppContext = () => {
    return useContext(AppContext);
};

export const AppContextProvider = ({ children }) => {
    // Initialize with sync value (will use fallback if config not loaded yet)
    const [backendUrl, setBackendUrl] = useState(getBackendUrl());
    const [showForgotPassword, setShowForgotPassword] = useState(false);
    const [showVerifyEmail, setShowVerifyEmail] = useState(false);
    const [showAddThread, setShowAddThread] = useState(false);

    // Update backend URL when config loads
    useEffect(() => {
        if (configPromise) {
            configPromise.then(url => {
                if (url && url !== backendUrl) {
                    setBackendUrl(url);
                }
            }).catch(err => {
                console.error('Failed to load backend URL:', err);
            });
        }
    }, []);

    return <AppContext.Provider value={{ backendUrl, showForgotPassword, setShowForgotPassword, showVerifyEmail, setShowVerifyEmail, showAddThread, setShowAddThread }}>{children}</AppContext.Provider>;
};
