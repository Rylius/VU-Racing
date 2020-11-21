<template>
    <div class="game">
        <waypoint v-if="track" :track="track"></waypoint>
        <player-status :track="track"></player-status>
        <checkpoint-update :track="track"></checkpoint-update>
        <scoreboard :track="track"></scoreboard>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {events} from './events';
import Waypoint from './Waypoint.vue';
import PlayerStatus from './PlayerStatus.vue';
import CheckpointUpdate from './CheckpointUpdate.vue';
import Scoreboard from './Scoreboard.vue';
import {Racing} from './types';

export default Vue.extend({
    name: 'Game',
    data(): { track: Racing.Track | null } {
        return {
            track: null,
        };
    },
    mounted() {
        events.$on('track:change', this.changeTrack);
    },
    methods: {
        changeTrack(track: Racing.Track) {
            this.track = track;
        },
    },
    components: {
        Waypoint,
        PlayerStatus,
        CheckpointUpdate,
        Scoreboard,
    },
});
</script>
