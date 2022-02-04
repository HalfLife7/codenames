import axios from "axios";

export type Card = {
    word: string,
    version: string
}

export const getCards = async (): Promise<Card[]> => {
    try {
        const {data} = await axios.get<Card[]>('http://localhost/api/cards');
        console.log('here', data);
        return data;
    } catch (e) {
        console.error(e);
        return [];
    }
}
