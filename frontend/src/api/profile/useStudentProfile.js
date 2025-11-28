import { getBackendUrl } from '../../utils/config.js';

const BASE_URL = getBackendUrl().replace(/\/$/, '') + '/api/profile';

  export const createStudentProfile = async (userId, data) => {
    const res = await fetch(`${BASE_URL}/${userId}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(data),
    });

    if (!res.ok) {
      throw new Error("Failed to create profile");
    }

    return await res.json();
  };


  export const getStudentProfile = async (userId) => {
    const res = await fetch(`${BASE_URL}/${userId}`, {
      method: "GET",
      credentials: "include",
    });

    if (!res.ok) {
      throw new Error("Failed to fetch profile");
    }

    return await res.json();
  };  

  export const updateStudentProfile = async (userId,data) => {
    const res = await fetch(`${BASE_URL}/${userId}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
      },
      credentials: "include",
      body: JSON.stringify(data),
    });

    if (!res.ok) {
      throw new Error("Failed to update profile");
    }

    return await res.json();
  };
