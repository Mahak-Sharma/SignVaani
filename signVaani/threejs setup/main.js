import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

let avatar;
let bones = {};
let defaultBoneQuaternions = {};
let motionData = [];
let frame = 0;
let playbackSpeed = 0.5;
let isPlayingGloss = false;
let animationStartTime = 0;
let animationDuration = 0;
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
function updateAvatar() {
    if (!motionData.length) return;

    const fps = 30;
    const elapsed = (performance.now() / 1000) - animationStartTime;
    const frameIndex = Math.min(
        Math.floor(elapsed * fps * playbackSpeed),
        motionData.length - 1
    );
    const frameData = motionData[frameIndex];
    if (!frameData || !frameData.bones) return;

    for (let name in frameData.bones) {
        if (!bones[name]) continue;
        const q = frameData.bones[name];
        bones[name].quaternion.set(q[0], q[1], q[2], q[3]);
    }
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
        motionData = data;
        frame = 0;
        const fps = 30;
        animationDuration = (motionData.length / fps) / playbackSpeed;
        isPlayingGloss = true;
        animationStartTime = performance.now() / 1000;

    } catch (err) {
        console.error("Invalid JSON received:", err);
    }
}

function animationFinished() {
    motionData = [];
    frame = 0;
    isPlayingGloss = false;
    resetAvatarPose();
    window.webkit.messageHandlers.avatarDone.postMessage("done");
}

window.playGlossFromJSON = playGlossFromJSON;
window.animationFinished = animationFinished;
