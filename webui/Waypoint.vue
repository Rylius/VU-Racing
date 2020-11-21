<template>
    <div class="waypoint" :style="{left, top}" v-show="visible">
        {{ icon }}
    </div>
</template>

<script lang="ts">
import Vue, {PropType} from 'vue';
import {events} from './events';
import {Racing} from './types';

export default Vue.extend({
    name: 'Waypoint',
    props: {
        track: {
            type: Object as PropType<Racing.Track>,
            required: true,
        },
    },
    data(): { checkpoint: number, finish: boolean, position: { x: number, y: number } } {
        return {
            checkpoint: 0,
            finish: false,
            position: {x: 0, y: 0},
        };
    },
    computed: {
        visible(): boolean {
            return this.track && this.checkpoint > 0;
        },
        left(): string {
            return `${this.position.x}px`;
        },
        top(): string {
            return `${this.position.y}px`;
        },
        icon(): string {
            if (this.finish) {
                return '🏁';
            } else {
                return '🏳️';
            }
        },
    },
    mounted() {
        events.$on('waypoint:update', this.updateWaypoint);
    },
    methods: {
        updateWaypoint(data: Racing.WaypointUpdate): void {
            this.checkpoint = data.number;
            this.finish = data.finish;
            this.position.x = data.position.x;
            this.position.y = data.position.y;
        },
    },
});
</script>
