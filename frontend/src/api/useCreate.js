import axios from 'axios';

import { getBackendUrl } from '../utils/config.js';

const BACKEND_ROOT = getBackendUrl();
const BASE_URL = BACKEND_ROOT.endsWith('/api')
  ? BACKEND_ROOT
  : BACKEND_ROOT.replace(/\/$/, '') + '/api';

export const createJobPosting = async (jobData, token) => {
  const payload = {
    ...jobData,
    requiredSkills: jobData.requiredSkills
      .split(',')
      .map((skill) => skill.trim()),
    batch: parseInt(jobData.batch, 10),
    relevanceScore: jobData.relevanceScore
      ? parseFloat(jobData.relevanceScore)
      : undefined,
  };
  
  const res = await axios.post(`${BASE_URL}/jobs`, payload, {
    headers: { Authorization: `Bearer ${token}` },
  });

  return res.data;
};