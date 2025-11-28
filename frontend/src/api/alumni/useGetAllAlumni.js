import { useState, useEffect } from "react";
import toast from "react-hot-toast";
import { getBackendUrl } from '../../utils/config.js';

const BASE_URL = getBackendUrl().replace(/\/$/, '') + '/api/alumni';

const useGetAllAlumni = () => {
  const [alumni, setAlumni] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchAllAlumni = async () => {
    setLoading(true);
    try {
      const res = await fetch(`${BASE_URL}`);
      const data = await res.json();
      if (!res.ok || data.message) {
        throw new Error(data.message || "Failed to fetch alumni");
      }

      setAlumni(data);
    } catch (error) {
      toast.error(error.message || "Error loading alumni");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAllAlumni(); // fetch on mount
  }, []);

  return { alumni, loading };
};

export default useGetAllAlumni;
