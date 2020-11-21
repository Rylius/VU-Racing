import {Vue} from 'vue/types/vue';

declare global {
    interface Window {
        trackChanged: (json: Racing.Track) => void;
        updateCheckpoint: (json: Racing.CheckpointUpdate) => void;
        checkpointReached: (json: Racing.CheckpointReached) => void;
        updateWaypoint: (json: Racing.WaypointUpdate) => void;
        updateTime: (json: Racing.TimeUpdate) => void;
        updatePosition: (json: Racing.PositionUpdate) => void;
        setScoreboardVisible: (visible: boolean) => void;
        updateScoreboard: (json: Racing.ScoreboardUpdate) => void;

        events: Vue | null;
    }
}

declare namespace Racing {

    interface Track {
        name: string;
        checkpoints: number;
    }

    interface PlayerStatus {
        checkpoint: number;
    }

    interface CheckpointUpdate {
        number: number;
    }

    interface CheckpointReached {
        number: number;
    }

    interface WaypointUpdate {
        number: number;
        position: { x: number, y: number };
        finish: boolean;
    }

    interface TimeUpdate {
        time: number;
        running: boolean;
    }

    interface PositionUpdate {
        position: number;
        total: number;
    }

    type ScoreboardUpdate = Array<{ id: number, name: string, time: number }>;

}
