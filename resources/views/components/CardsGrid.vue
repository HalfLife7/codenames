<template>
    <div class="grid grid-rows-5 grid-cols-5 gap-2 p-4">
        <template v-for="(card, index) in cards">
            <Card v-if="index < 25" :word="card.word" :key="`card-${index}`"></Card>
        </template>
    </div>
</template>

<script lang="ts">
import {defineComponent, onMounted, Ref, ref} from "vue";
import {Card, getCards} from "@/scripts/services/CardService";
import Card from "@/views/components/Card.vue";


export default defineComponent({
    name: 'CardsGrid',
    components: {Card},
    setup(){
        const cards: Ref<Card[]> = ref([]);
        onMounted( async () => {
             cards.value = await getCards();
        })
        return {cards}
    }
})
</script>

<style scoped>

</style>
