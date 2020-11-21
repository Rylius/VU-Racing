<template>
    <div class="checkpoint-update" :class="[visible]" v-show="track">
        <template v-if="track">
            <div class="checkpoint">
                Checkpoint {{ checkpoint }}/{{ track.checkpoints }}
            </div>

            <div class="time" v-if="false">
                Time ?:?:?
            </div>
        </template>
    </div>
</template>

<script lang="ts">
import Vue from 'vue';
import {events} from './events';
import {Racing} from './types';

export default Vue.extend({
    name: 'CheckpointUpdate',
    props: [
        'track',
    ],
    data() {
        return {
            checkpoint: 0,
            visible: '',
            timeoutId: 0,
        };
    },
    mounted() {
        events.$on('checkpoint:reached', this.update);
    },
    methods: {
        update(data: Racing.CheckpointReached) {
            this.checkpoint = data.number;

            if (this.checkpoint > 0) {
                this.visible = 'visible';
                if (this.timeoutId) {
                    clearTimeout(this.timeoutId);
                }
                this.timeoutId = setTimeout(() => this.visible = '', 2000);
            }
        },
    },
});
</script>

<style lang="scss" scoped>

.checkpoint-update {
  transition: opacity 1s linear;
  opacity: 0;

  &.visible {
    transition: opacity 0.1s linear;
    opacity: 1;
  }
}

</style>
