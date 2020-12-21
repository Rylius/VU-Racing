<template>
    <div class="scoreboard" :class="{visible}">
        <h2>{{ track.name }}</h2>
        <table>
            <thead>
            <tr>
                <th>Position</th>
                <th>Player</th>
                <th>Time</th>
            </tr>
            </thead>
            <tbody>
            <tr v-for="(entry, i) in scoreboard">
                <td>{{ i + 1 }}</td>
                <td>{{ entry ? entry.name : '???' }}</td>
                <td>{{ (entry ? entry.time : 0) | time }}</td>
            </tr>
            </tbody>
        </table>
    </div>
</template>

<script lang="ts">
import Vue, {PropType} from 'vue';
import {events} from './events';
import {Racing} from './types';

export default Vue.extend({
    name: 'Scoreboard',
    props: {
        track: {
            type: Object as PropType<Racing.Track>,
            required: true,
        },
    },
    data(): { visible: boolean, scoreboard: Racing.ScoreboardUpdate } {
        return {
            visible: false,
            scoreboard: [],
        };
    },
    mounted() {
        events.$on('scoreboard:visible', (visible: boolean) => this.visible = visible);
        events.$on('scoreboard:data', (data: Racing.ScoreboardUpdate) => this.scoreboard = data);
    },
});
</script>
