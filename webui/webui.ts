import Vue from 'vue';

import Game from './Game.vue';
import {events} from './events';
import {Racing} from './types';

Vue.config.productionTip = false;

Vue.filter('time', (value: number) => {
    if (value < 0) {
        return 'N/A';
    }

    // @ts-ignore
    const minutes = Math.floor(value / 60000).toFixed(0).padStart(2, '0');
    // @ts-ignore
    const seconds = Math.floor((value % 60000) / 1000).toFixed(0).padStart(2, '0');
    // @ts-ignore
    const milliseconds = (value % 1000).toFixed(0).padStart(3, '0');
    return `${minutes}:${seconds}:${milliseconds}`;
});

const vue = new Vue({
    el: '#app',
    render: h => h(Game),
});

window.trackChanged = function (json: Racing.Track) {
    events.$emit('track:change', json);
};

window.updateCheckpoint = function (json: Racing.CheckpointUpdate) {
    events.$emit('checkpoint:update', json);
};

window.checkpointReached = function (json: Racing.CheckpointReached) {
    events.$emit('checkpoint:reached', json);
};

window.updateWaypoint = function (json: Racing.WaypointUpdate) {
    events.$emit('waypoint:update', json);
};

window.updateTime = function (json: Racing.TimeUpdate) {
    events.$emit('time:update', json);
};

window.updatePosition = function (json: Racing.PositionUpdate) {
    events.$emit('position:update', json);
};

window.setScoreboardVisible = function (visible: boolean) {
    events.$emit('scoreboard:visible', visible);
};

window.updateScoreboard = function (json: Racing.ScoreboardUpdate) {
    events.$emit('scoreboard:data', json);
};

// @ts-ignore
if (process.env.NODE_ENV === 'development') {
    window.events = events;

    window.trackChanged({name: 'Test Track', checkpoints: 20});
    window.checkpointReached({number: 1});
    window.updateCheckpoint({number: 1});
    window.updateWaypoint({number: 2, position: {x: 512, y: 512}, finish: false});
    window.updateTime({time: (2 * 60000) + (37 * 1000) + 381, running: true});
    window.setScoreboardVisible(true);
    window.updateScoreboard([{id: 1, name: 'TestPlayer', time: 12345}, {id: 2, name: 'OtherPlayer', time: 23456}]);
}
