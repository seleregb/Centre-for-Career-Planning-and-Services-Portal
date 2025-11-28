import axios from 'axios';
import { getBackendUrl } from '../utils/config.js';

const BASE_URL = getBackendUrl();
const axiosInstance = axios.create({
  baseURL: BASE_URL,
});

export const fetchJobs = async () => {
  try {
    const res = await axiosInstance.get('/api/jobs');
    // Check if the response data is an array directly, or if it's nested (e.g., res.data.jobs)
    const jobs = Array.isArray(res.data) ? res.data : res.data.jobs || [];
    console.log('Fetched Jobs Data:', jobs);
    return jobs;
  } catch (err) {
    console.error('Error fetching jobs:', err.response?.data || err.message);
    return [];
  }
};

export const fetchMyApplications = async () => {
  const token = localStorage.getItem('ccps-token');
  if (!token) {
    return { onCampus: [], offCampus: [] };
  }
  try {
    const res = await axiosInstance.get('/api/applications/my', {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    
    // BACKEND CONTROLLER FIX: Mapping backend keys (onCampusApplications) 
    // to frontend state keys (onCampus).
    return { 
      onCampus: res.data.onCampusApplications || [],
      offCampus: res.data.offCampusApplications || [],
    };
  } catch (err) {
    console.error('Error fetching my applications:', err.response?.data || err.message);
    return { onCampus: [], offCampus: [] };
  }
};

export const fetchAppliedJobs = async () => {
  const token = localStorage.getItem("ccps-token");
  try {
    const res = await axiosInstance.get('/api/applications/applied-jobs', {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    // The backend controller exports the key 'appliedJobs', so this looks correct.
    return res.data.appliedJobs || [];
  } catch (err) {
    console.error("Applied Jobs API error:", err.response?.data || err.message);
    return [];
  }
};

export const applyToJob = async (jobData) => {
  const token = localStorage.getItem("ccps-token");
  try {
    // The backend controller uses the '/api/applications' route for POST requests
    const res = await axiosInstance.post('/api/applications', jobData, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    return res.data;
  } catch (err) {
    console.error("Apply Job API error:", err.response?.data || err.message);
    throw new Error(err.response?.data?.message || 'Failed to submit application');
  }
};

export const fetchApplicants = async (jobId) => {
  const token = localStorage.getItem("ccps-token");
  try {
    const res = await axiosInstance.get(`/api/applications/job/${jobId}/applicants`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });
    console.log("Raw applicants API response:", res.data);
    return res.data.applicants || [];
  } catch (err) {
    console.error("Applicants API error:", err.response?.data || err.message);
    return [];
  }
};

export const updateApplicationStatus = async (id, status) => {
  const token = localStorage.getItem("ccps-token");
  await axiosInstance.put(`/api/applications/status/${id}`, { status }, {
    headers: {
      Authorization: `Bearer ${token}`,
    },
  });
};

export const saveJob = async (jobId) => {
  const res = await axiosInstance.post("/api/applications/save", { jobId });
  return res.data;
};

export const fetchSavedApplications = () =>
  axiosInstance
    .get("/api/applications/saved")
    .then((res) => res.data.savedApplications);
