import { useState, useEffect } from "react";
import { getBackendUrl } from '../../utils/config.js';

const BASE_URL = getBackendUrl().replace(/\/$/, '') + '/api';

export const useReferrals = () => {
    const [referrals, setReferrals] = useState([]);

    useEffect(() => {
        fetch(`${BASE_URL}/referrals`)
            .then((res) => res.json())
            .then(setReferrals)
            .catch((err) => console.error(err));
    }, []);

    return { referrals };
};