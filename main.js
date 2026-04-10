import { default as gulls } from "./gulls/gulls.js";
import { default as Mouse } from "./gulls/helpers/mouse.js";
import { Pane } from "https://cdn.jsdelivr.net/npm/tweakpane@4.0.5/dist/tweakpane.min.js";

async function webgpu_init() {
  const sg = await gulls.init(),
    size = window.innerWidth * window.innerHeight,
    state = new Float32Array(size * 2);

  const frag = await gulls.import("./frag.wgsl"),
    frag_shader = gulls.constants.vertex + frag,
    compute = await gulls.import('./compute.wgsl');

  for (let i = 0; i < size; i++) {
    state[i * 2 + 0] = 1.0;
    state[i * 2 + 1] = Math.floor(Math.random() * 100) == 0.0;
  }

  const pane = new Pane();
  const params = { d_a: 1.0, d_b: 0.5, feed: 0.055, kill: 0.062 };
  const dist_strength = { d_a: 0.0, d_b: 0.0, feed: 0.0, kill: 0.0 };
  const params_uniform = sg.uniform(Object.values(params));
  const dist_strength_uniform = sg.uniform(Object.values(dist_strength));

  pane.addBinding(params, "d_a", { min: 0, max: 1, label: 'd_a' }).on('change', v => params_uniform.value = Object.values(params));
  pane.addBinding(params, "d_b", { min: 0, max: 1, label: 'd_b' }).on('change', v => params_uniform.value = Object.values(params));
  pane.addBinding(params, "feed", { min: 0, max: 1, label: 'feed' }).on('change', v => params_uniform.value = Object.values(params));
  pane.addBinding(params, "kill", { min: 0, max: 1, label: 'kill' }).on('change', v => params_uniform.value = Object.values(params));
  pane.addBinding(dist_strength, "d_a", { min: -1, max: 1, label: 'd_a_dist' }).on('change', v => dist_strength_uniform.value = Object.values(params));
  pane.addBinding(dist_strength, "d_b", { min: -1, max: 1, label: 'd_b_dist' }).on('change', v => dist_strength_uniform.value = Object.values(params));
  pane.addBinding(dist_strength, "feed", { min: -1, max: 1, label: 'feed_dist' }).on('change', v => dist_strength_uniform.value = Object.values(params));
  pane.addBinding(dist_strength, "kill", { min: -1, max: 1, label: 'kill_dist' }).on('change', v => dist_strength_uniform.value = Object.values(params));

  const statebuffer1 = sg.buffer(state);
  const statebuffer2 = sg.buffer(state);
  const res = sg.uniform([window.innerWidth, window.innerHeight]);

  Mouse.init();

  const mouse = sg.uniform(Mouse.values);

  const render_pass = await sg.render({
    shader: frag_shader,
    data: [
      res,
      sg.pingpong(statebuffer1, statebuffer2)
    ],
  });

  const compute_pass = sg.compute({
    shader: compute,
    data: [
      res,
      sg.pingpong(statebuffer1, statebuffer2),
      mouse,
      params_uniform,
      dist_strength_uniform,
    ],
    onframe() { mouse.value = Mouse.values },
    dispatchCount: [Math.round(gulls.width / 8), Math.round(gulls.height / 8), 1],
    times: 10,
  })

  sg.run(compute_pass, render_pass)
}

webgpu_init()
  .then((res) => console.log("WebGPU init ran"))
  .catch((err) => console.error(err));
