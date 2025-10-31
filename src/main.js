import './style.css'
import * as THREE from 'three'
import vertexShader from './shader/lego-pixel/vertex.glsl'
import fragmentShader from './shader/lego-pixel/fragment.glsl'
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls'
import trailFragment from './shader/trail/fragment.glsl'
import { Pane } from 'tweakpane'

const globalUniforms = {
	uTime: { value: 0.0 },
}

/**
 * Debug
 */
// __gui__
const config = {
	subdivision: 20,
	lightAngle: (Math.PI * 3) / 4,
	trail: {
		size: 0.15,
	},
}
const pane = new Pane()

pane
	.addBinding(config, 'subdivision', {
		min: 1,
		max: 200,
		step: 1,
	})
	.on('change', (ev) => {
		groundMaterial.uniforms.uSubdivision.value = ev.value
	})

pane
	.addBinding(config, 'lightAngle', {
		min: -Math.PI * 2,
		max: Math.PI * 2,
		step: 0.01,
	})
	.on('change', (ev) => {
		groundMaterial.uniforms.uLightAngle.value = ev.value
	})

{
	const trail = pane.addFolder({ title: 'Trail', expanded: true })

	trail
		.addBinding(config.trail, 'size', {
			min: 0.01,
			max: 0.5,
			step: 0.01,
		})
		.on('change', (ev) => {
			trailMaterial.uniforms.uSize.value = ev.value
		})
}

/**
 * Scene
 */
const scene = new THREE.Scene()
// scene.background = new THREE.Color(0xadadff)

// __floor__
/**
 * Texture Loader
 */
const textureLoader = new THREE.TextureLoader()
const legoTexture = textureLoader.load('/lego-1x1.jpeg')
const avatarTexture = textureLoader.load('/lego-avatar.png')
avatarTexture.colorSpace = THREE.SRGBColorSpace

/**
 * Plane
 */
const groundMaterial = new THREE.ShaderMaterial({
	vertexShader,
	fragmentShader,
	uniforms: {
		uLegoTexture: new THREE.Uniform(legoTexture),
		uAvatarTexture: new THREE.Uniform(avatarTexture),
		uSubdivision: new THREE.Uniform(config.subdivision),
		uLightAngle: new THREE.Uniform(config.lightAngle),
		uTrailTexture: new THREE.Uniform(null),
	},
})
const groundGeometry = new THREE.PlaneGeometry(10, 10)
// groundGeometry.rotateX(-Math.PI * 0.5)
const ground = new THREE.Mesh(groundGeometry, groundMaterial)
scene.add(ground)

/**
 * render sizes
 */
const sizes = {
	width: window.innerWidth,
	height: window.innerHeight,
}

/**
 * Camera
 */
const fov = 60
const camera = new THREE.PerspectiveCamera(fov, sizes.width / sizes.height, 0.1)
camera.position.set(0, 0, 10)
camera.lookAt(new THREE.Vector3(0, 2.5, 0))

/**
 * Show the axes of coordinates system
 */
// __helper_axes__
const axesHelper = new THREE.AxesHelper(3)
// scene.add(axesHelper)

/**
 * renderer
 */
const renderer = new THREE.WebGLRenderer({
	antialias: window.devicePixelRatio < 2,
})
document.body.appendChild(renderer.domElement)

function createRenderTarget(mipmap = false, w = sizes.width, h = sizes.height) {
	return new THREE.WebGLRenderTarget(w, h, {
		type: THREE.HalfFloatType,
		minFilter: THREE.LinearFilter,
		magFilter: THREE.LinearFilter,
		depthBuffer: false,
		generateMipmaps: mipmap,
		depthBuffer: false,
		stencilBuffer: false,
	})
}

const trailRes = {
	width: 200,
	height: 200,
}

const rt1 = createRenderTarget(false, trailRes.width, trailRes.height)
const rt2 = createRenderTarget(false, trailRes.width, trailRes.height)

let inputRT = rt1
let outputRT = rt2

const trailScene = new THREE.Scene()
const trailGeometry = new THREE.BufferGeometry()
trailGeometry.setAttribute(
	'position',
	new THREE.BufferAttribute(
		new Float32Array([-1, -1, 0, 3, -1, 0, -1, 3, 0]),
		3
	)
)
trailGeometry.setAttribute(
	'uv',
	new THREE.BufferAttribute(new Float32Array([0, 0, 2, 0, 0, 2]), 2)
)
const trailMaterial = new THREE.ShaderMaterial({
	vertexShader: /* glsl */ `
		varying vec2 vUv;	
		void main() {
			vUv = uv;
			gl_Position = vec4(position,1.0);
		}
	`,
	fragmentShader: trailFragment,
	uniforms: {
		uResolution: new THREE.Uniform(
			new THREE.Vector2(trailRes.width, trailRes.height)
		),
		uMap: new THREE.Uniform(outputRT.texture),
		uUVPointer: new THREE.Uniform(new THREE.Vector2(0.5, 0.5)),
		uDt: new THREE.Uniform(0.0),
		uSpeed: new THREE.Uniform(0),
		uTime: globalUniforms.uTime,
		uSize: new THREE.Uniform(config.trail.size),
		uPointerSpeed: new THREE.Uniform(new THREE.Vector2(0)),
	},
})

const trailMesh = new THREE.Mesh(trailGeometry, trailMaterial)
trailScene.add(trailMesh)

const pointer = new THREE.Vector2(0, 0)
const raycaster = new THREE.Raycaster()
window.addEventListener('pointermove', (ev) => {
	pointer.x = (ev.clientX / sizes.width) * 2 - 1
	pointer.y = -(ev.clientY / sizes.height) * 2 + 1
})

handleResize()

/**
 * OrbitControls
 */
// __controls__
const controls = new OrbitControls(camera, renderer.domElement)
controls.enableDamping = true

/**
 * Lights
 */
const ambientLight = new THREE.AmbientLight(0xffffff, 1.5)
const directionalLight = new THREE.DirectionalLight(0xffffff, 4.5)
directionalLight.position.set(3, 10, 7)
scene.add(ambientLight, directionalLight)

/**
 * Three js Clock
 */
// __clock__
const clock = new THREE.Clock()
let time = 0

/**
 * frame loop
 */
function tic() {
	/**
	 * tempo trascorso dal frame precedente
	 */
	// const deltaTime = clock.getDelta()
	/**
	 * tempo totale trascorso dall'inizio
	 */
	// const time = clock.getElapsedTime()
	const dt = clock.getDelta()
	time += dt

	// __controls_update__
	controls.update()

	raycaster.setFromCamera(pointer, camera)
	const intersects = raycaster.intersectObject(ground)
	if (intersects.length > 0) {
		const uv = intersects[0].uv

		const prevUV = trailMaterial.uniforms.uUVPointer.value.clone()
		trailMaterial.uniforms.uPointerSpeed.value.lerp(
			trailMaterial.uniforms.uUVPointer.value.clone().sub(prevUV),
			dt * 4
		)

		trailMaterial.uniforms.uUVPointer.value.lerp(uv, dt * 10)
	}

	globalUniforms.uTime.value = time
	trailMaterial.uniforms.uDt.value = dt

	renderer.setRenderTarget(outputRT)
	renderer.render(trailScene, camera)

	renderer.setRenderTarget(null)

	trailMaterial.uniforms.uMap.value = outputRT.texture
	groundMaterial.uniforms.uTrailTexture.value = outputRT.texture

	renderer.render(scene, camera)

	const temp = inputRT
	inputRT = outputRT
	outputRT = temp

	requestAnimationFrame(tic)
}

requestAnimationFrame(tic)

window.addEventListener('resize', handleResize)

function handleResize() {
	sizes.width = window.innerWidth
	sizes.height = window.innerHeight

	camera.aspect = sizes.width / sizes.height

	// camera.aspect = sizes.width / sizes.height;
	camera.updateProjectionMatrix()

	renderer.setSize(sizes.width, sizes.height)

	const pixelRatio = Math.min(window.devicePixelRatio, 2)
	renderer.setPixelRatio(pixelRatio)
}
