import { useState } from 'react';
import { useAuthContext } from '../../context/AuthContext';
import { getBackendUrlSync } from '../../utils/config.js';

const BASE_URL = getBackendUrlSync().replace(/\/$/, '') + '/api/referrals';

export const useProvideReferral = () => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const { authUser } = useAuthContext();

  const provideReferral = async (referralId, referralLink) => {
    setIsSubmitting(true);
    setError(null);

    try {
      const response = await fetch(`${BASE_URL}/provide`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        credentials: 'include',
        body: JSON.stringify({
          referralId,
          referralLink,
          alumniEmail: authUser.email
        })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to provide referral');
      }

      const data = await response.json();
      return data;
    } catch (error) {
      setError(error.message || 'Error providing referral');
      throw error;
    } finally {
      setIsSubmitting(false);
    }
  };

  return { provideReferral, isSubmitting, error };
};