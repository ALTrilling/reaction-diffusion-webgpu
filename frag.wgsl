@group(0) @binding(0) var<uniform> res:   vec2f;
@group(0) @binding(1) var<storage> state: array<f32>;

@fragment 
fn fs( @builtin(position) pos : vec4f ) -> @location(0) vec4f {
  let x = u32(floor(pos.x));
  let y = u32(floor(pos.y));
  let width = u32(res.x);
  let idx = y * width + x;
  let v = state[ idx * 2 ];
  return vec4f( v,v,v, 1.);
}
