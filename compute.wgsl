@group(0) @binding(0) var<uniform> res: vec2f;
@group(0) @binding(1) var<storage> statein: array<f32>;
@group(0) @binding(2) var<storage, read_write> stateout: array<f32>;
@group(0) @binding(3) var<uniform> mouse: vec3f;
@group(0) @binding(4) var<uniform> props: vec4f;
@group(0) @binding(5) var<uniform> dist_strength: vec4f;

fn index( x:i32, y:i32, b: bool ) -> u32 {
  let _res = vec2i(res);
  return u32(
    (
      (
        (y % _res.y) + _res.y) % _res.y) * _res.x +
        ((x % _res.x) + _res.x) % _res.x ) * 2 +
        // Some might claim that it is possible to do this through methods other than casting to `u32`. I say, "explosion"
        u32(b);
}

fn laplacian(x: i32, y: i32, b: bool) -> f32 {
  return statein[ index(x + 1, y + 1, b) ] * 0.05 +
         statein[ index(x + 1, y, b)     ] * 0.20 +
         statein[ index(x + 1, y - 1, b) ] * 0.05 +
         statein[ index(x, y - 1, b)     ] * 0.20 +
         statein[ index(x - 1, y - 1, b) ] * 0.05 +
         statein[ index(x - 1, y, b)     ] * 0.20 +
         statein[ index(x - 1, y + 1, b) ] * 0.05 +
         statein[ index(x, y + 1, b)     ] * 0.20 +
         statein[ index(x, y, b)         ] * -1;
}

@compute
@workgroup_size(8,8)
fn cs(@builtin(global_invocation_id) _cell: vec3u ) {
  let cell = vec3i(_cell);
  let _res = vec2i(res);
  if (cell.x >= _res.x || cell.y >= _res.y) { return; }
  let aspect = res.x / res.y;
  let center_dist = length(
    vec2f(
      f32(_cell.x),
      f32(_cell.y)) - vec2(0.5) * res
  ) / 5000.0;

  let d_a  = props.x + center_dist * dist_strength.x;
  let d_b  = props.y + center_dist * dist_strength.y;
  let feed = props.z + center_dist * dist_strength.z;
  let kill = props.w + center_dist * dist_strength.w;
  let delta_time = 1.0;

  let old_a = statein[ index(cell.x, cell.y, false) ];
  let old_b = statein[ index(cell.x, cell.y, true ) ];

  let new_a = old_a + (d_a * laplacian(cell.x, cell.y, false) - old_a * old_b * old_b + feed * (1 - old_a)) * delta_time;
  let new_b = old_b + (d_b * laplacian(cell.x, cell.y, true ) + old_a * old_b * old_b - (kill + feed) * old_b) * delta_time;

  let mouse_status = mouse.z != 0.0 && (length(vec2f(cell.xy) / res - mouse.xy) < 0.03);
  stateout[ index(cell.x, cell.y, false) ] = clamp(select(new_a, 0.0, mouse_status), 0.0, 1.0);
  stateout[ index(cell.x, cell.y, true ) ] = clamp(select(new_b, 1.0, mouse_status), 0.0, 1.0);
}
