import {useState} from 'react'
import toast from 'react-hot-toast'
import { getBackendUrl } from '../../utils/config.js';

const BASE_URL = getBackendUrl().replace(/\/$/, '') + '/api';

const useUpdateAnalytics = () => {
    
    const [editLoading, setEditLoading] = useState(false);
    const updateAnalytics = async(data) => {
        setEditLoading(true)
        try {
            const res = await fetch(`${BASE_URL}/stats`,{
                method: "PUT",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify(data)
            })
        }
        catch(error){
            toast.error(error.message);
        }
        finally{
            setEditLoading(false)
        }
    }

    return {editLoading, updateAnalytics}
}

export default useUpdateAnalytics;