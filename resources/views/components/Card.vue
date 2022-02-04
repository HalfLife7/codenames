<template>
    <div class="p-4 rounded shadow-md bg-orange-200">
        {{word}}
    </div>
</template>

<script lang="ts">
import {defineComponent} from "vue";

export default defineComponent({
    name: "Card",
    props: {
        word: { type: String, required: true },
    },
    setup() {
    }
})
</script>

<style scoped>

</style>
