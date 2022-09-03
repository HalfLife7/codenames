<template>
    <div>

        <CardsGrid></CardsGrid>
        <ul>
            <li v-for="message in messages">
                {{ message }}
            </li>
        </ul>
    </div>
</template>

<script lang="ts">
import Pusher from "pusher-js";
import {defineComponent} from 'vue';
import HelloWorld from './components/HelloWorld.vue';
import CardsGrid from "@/views/components/CardsGrid.vue";


export default defineComponent({
    name: 'App',
    components: {
        CardsGrid,
        HelloWorld,
    },
    data() {
        return {
            messages: []
        }
    },
    created() {
        // Enable pusher logging - don't include this in production
        Pusher.logToConsole = true;

        var pusher = new Pusher('bc90fa5eb763f6cfcfff', {
            cluster: 'us2'
        });

        var channel = pusher.subscribe('my-channel');
        channel.bind('my-event', function (data: any) {
            this.messages.push(JSON.stringify(data));
        });
    }
});
</script>
