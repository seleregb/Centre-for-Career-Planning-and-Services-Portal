import { useState } from 'react';
import { getBackendUrlSync } from '../../utils/config.js';

const BASE_URL = getBackendUrlSync().replace(/\/$/, '') + '/api/referrals';

export const useDeleteReferral = () => {
  const [isDeleting, setIsDeleting] = useState(false);
  const [error, setError] = useState(null);

  const deleteReferral = async (referralId) => {
    setIsDeleting(true);
    setError(null);

    try {
      const response = await fetch(`${BASE_URL}/${referralId}`, {
        method: "DELETE",
        headers: {
          'Content-Type': 'application/json'
        },
        credentials: 'include'
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to delete referral');
      }

      const data = await response.json();
      return data;
    } catch (error) {
      setError(error.message || 'Error deleting referral');
      throw error;
    } finally {
      setIsDeleting(false);
    }
  };

  return { deleteReferral, isDeleting, error };
};