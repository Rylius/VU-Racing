<template>
    <div class="position-info" v-show="track">
        <template v-if="track">
            <div class="position">
                Position {{ position }}/{{ playerCount }}
            </div>

            <div class="time">
                Time {{ time | time }}
            </div>

            <!--      <div class="lap">-->
            <!--        Lap ?/?-->
            <!--      </div>-->

            <div class="checkpoint">
                Checkpoint {{ checkpoint }}/{{ track.checkpoints }}
            </div>
        </template>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {events} from './events';
import {Racing} from './types';

export default Vue.extend({
    name: 'PlayerStatus',
    props: [
        'track',
    ],
    data() {
        return {
            checkpoint: 0,
            time: 0,
            timeRunning: false,
            timeIntervalId: -1,
            position: 0,
            playerCount: 0,
        };
    },
    mounted() {
        events.$on('checkpoint:update', this.updateCheckpoint);
        events.$on('time:update', this.updateTime);
        events.$on('position:update', this.updatePosition);
    },
    methods: {
        updateCheckpoint(data: Racing.CheckpointUpdate): void {
            this.checkpoint = data.number;
        },
        updateTime(data: Racing.TimeUpdate): void {
            this.time = data.time;
            this.timeRunning = data.running;

            if (this.timeRunning && this.timeIntervalId <= 0) {
                const interval = 67;
                this.timeIntervalId = setInterval(() => this.time += interval, interval);
            } else if (!this.timeRunning && this.timeIntervalId > 0) {
                clearInterval(this.timeIntervalId);
                this.timeIntervalId = -1;
            }
        },
        updatePosition(data: Racing.PositionUpdate): void {
            this.position = data.position;
            this.playerCount = data.total;
        },
    },
});
</script>

<style lang="less" scoped>

</style>
