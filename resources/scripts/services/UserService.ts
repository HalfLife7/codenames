import axios from "axios";

interface User {
    id: number;
    name: string;
}

export const getUsers = async (): Promise<User[]> => {
    try {
        const { data } = await axios.get<User[]>(`http://localhost/api/users`)
        return data;
    } catch (e) {
        console.error(e);
        return [];
    }
}
