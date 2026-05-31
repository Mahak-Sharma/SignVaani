import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

let avatar;
let bones = {};
let defaultBoneQuaternions = {};
let motionData = [];
let lastMotionData = [];
let frame = 0;
let playbackSpeed = 0.5;
let isPlayingGloss = false;
let isPaused = false;
let animationStartTime = 0;
let animationDuration = 0;
let pausedElapsed = 0;
const scene = new THREE.Scene();
scene.background = null;
const camera = new THREE.PerspectiveCamera(15, window.innerWidth / window.innerHeight, 0.1, 1000);
camera.position.set(0, 2.5, 4);
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha:true });
renderer.setSize(window.innerWidth, window.innerHeight);
document.body.appendChild(renderer.domElement);
scene.add(new THREE.AmbientLight(0xffffff, 0.8));
const light = new THREE.DirectionalLight(0xffffff, 5);
light.position.set(5, 4, 5);
scene.add(light);
new GLTFLoader().load("Vaani.glb", function(gltf) {
    avatar = gltf.scene;
    scene.add(avatar);
    avatar.position.set(0, 0, 0);
    avatar.traverse(child => {
        if (child.isBone) {
            bones[child.name] = child;
            defaultBoneQuaternions[child.name] = child.quaternion.clone();
        }
    });
    console.log("Avatar loaded. Bones found:", Object.keys(bones).length);
});
function resetAvatarPose() {
    for (const name in defaultBoneQuaternions) {
        if (!bones[name]) continue;
        bones[name].quaternion.copy(defaultBoneQuaternions[name]);
    }
}

function applyFrame(frameData) {
    if (!frameData || !frameData.bones) return;

    for (let name in frameData.bones) {
        if (!bones[name]) continue;
        const q = frameData.bones[name];
        bones[name].quaternion.set(q[0], q[1], q[2], q[3]);
    }
}

function renderFrameAtElapsed(elapsed) {
    if (!motionData.length) return;

    const fps = 30;
    const frameIndex = Math.min(
        Math.floor(elapsed * fps * playbackSpeed),
        motionData.length - 1
    );
    const frameData = motionData[frameIndex];
    applyFrame(frameData);
}

function updateAvatar() {
    if (!motionData.length) return;

    const elapsed = (performance.now() / 1000) - animationStartTime;
    renderFrameAtElapsed(elapsed);
}
function animate() {
    requestAnimationFrame(animate);
    if (isPlayingGloss) {
        updateAvatar();
        const elapsed = (performance.now() / 1000) - animationStartTime;
        if (elapsed >= animationDuration) {
            isPlayingGloss = false;
            animationFinished();
        }
    }
    camera.lookAt(0, 1.28, 0);
    renderer.render(scene, camera);
}
animate();
function playGlossFromJSON(data) {
    try {
        console.log("Received animation frames:", data.length);
        lastMotionData = Array.isArray(data) ? data : [];
        motionData = lastMotionData;
        frame = 0;
        const fps = 30;
        animationDuration = (motionData.length / fps) / playbackSpeed;
        pausedElapsed = 0;
        isPaused = false;
        isPlayingGloss = true;
        animationStartTime = performance.now() / 1000;
        renderFrameAtElapsed(0);

    } catch (err) {
        console.error("Invalid JSON received:", err);
    }
}

function pauseGlossPlayback() {
    if (!isPlayingGloss || !motionData.length) return;

    pausedElapsed = Math.max(0, (performance.now() / 1000) - animationStartTime);
    isPlayingGloss = false;
    isPaused = true;
    renderFrameAtElapsed(pausedElapsed);
}

function resumeGlossPlayback() {
    if (!motionData.length) {
        replayLastGloss();
        return;
    }

    if (!isPaused) return;

    animationStartTime = (performance.now() / 1000) - pausedElapsed;
    isPaused = false;
    isPlayingGloss = true;
}

function stopGlossPlayback() {
    motionData = [];
    frame = 0;
    pausedElapsed = 0;
    isPaused = false;
    isPlayingGloss = false;
    resetAvatarPose();
}

function rewindGlossPlayback(seconds = 0.75) {
    const safeSeconds = Math.max(Number(seconds) || 0, 0);

    if (!motionData.length) {
        replayLastGloss();
        return;
    }

    const currentElapsed = isPaused
        ? pausedElapsed
        : Math.max(0, (performance.now() / 1000) - animationStartTime);
    const newElapsed = Math.max(0, currentElapsed - safeSeconds);

    if (isPaused) {
        pausedElapsed = newElapsed;
    } else {
        animationStartTime = (performance.now() / 1000) - newElapsed;
    }

    renderFrameAtElapsed(newElapsed);
}

function forwardGlossPlayback(seconds = 0.75) {
    const safeSeconds = Math.max(Number(seconds) || 0, 0);

    if (!motionData.length) return;

    const now = performance.now() / 1000;
    const currentElapsed = isPaused
        ? pausedElapsed
        : Math.max(0, now - animationStartTime);
    const newElapsed = Math.min(animationDuration, currentElapsed + safeSeconds);

    if (newElapsed >= animationDuration) {
        pausedElapsed = 0;
        isPaused = false;
        isPlayingGloss = false;
        animationFinished();
        return;
    }

    if (isPaused) {
        pausedElapsed = newElapsed;
    } else {
        animationStartTime = now - newElapsed;
    }

    renderFrameAtElapsed(newElapsed);
}

function restartGlossPlayback() {
    if (motionData.length) {
        playGlossFromJSON(motionData);
        return;
    }

    replayLastGloss();
}

function replayLastGloss() {
    if (!lastMotionData.length) return;
    playGlossFromJSON(lastMotionData);
}

function animationFinished() {
    motionData = [];
    frame = 0;
    pausedElapsed = 0;
    isPlayingGloss = false;
    isPaused = false;
    resetAvatarPose();
    window.webkit.messageHandlers.avatarDone.postMessage("done");
}

window.playGlossFromJSON = playGlossFromJSON;
window.pauseGlossPlayback = pauseGlossPlayback;
window.resumeGlossPlayback = resumeGlossPlayback;
window.stopGlossPlayback = stopGlossPlayback;
window.rewindGlossPlayback = rewindGlossPlayback;
window.forwardGlossPlayback = forwardGlossPlayback;
window.restartGlossPlayback = restartGlossPlayback;
window.replayLastGloss = replayLastGloss;
window.animationFinished = animationFinished;
