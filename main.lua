function mat4_identity()
  return {
    {1, 0, 0, 0},
    {0, 1, 0, 0},
    {0, 0, 1, 0},
    {0, 0, 0, 1}
  }
end

function vec4(x, y, z)
  return {x, y, z, 1}
end

function mat4_mult_vec4(m, v)
  local res = {0, 0, 0, 0}
  for i = 1, 4 do
    for j = 1, 4 do
      res[i] = res[i] + m[i][j] * v[j]
    end
  end
  return res
end

function mat4_mult(a, b)
  local res = {}
  for i = 1, 4 do
    res[i] = {}
    for j = 1, 4 do
      local sum = 0
      for k = 1, 4 do
        sum = sum + a[i][k] * b[k][j]
      end
      res[i][j] = sum
    end
  end
  return res
end

function mat4_translation(tx, ty, tz)
  return {
    {1, 0, 0, tx},
    {0, 1, 0, ty},
    {0, 0, 1, tz},
    {0, 0, 0, 1}
  }
end

function mat4_rotate_x(theta)
  local c, s = math.cos(theta), math.sin(theta)
  return {
    {1, 0, 0, 0},
    {0, c, -s, 0},
    {0, s, c, 0},
    {0, 0, 0, 1}
  }
end

function mat4_rotate_y(theta)
  local c, s = math.cos(theta), math.sin(theta)
  return {
    {c, 0, -s, 0},
    {0, 1, 0, 0},
    {s, 0, c, 0},
    {0, 0, 0, 1}
  }
end

function mat4_rotate_z(theta)
  local c, s = math.cos(theta), math.sin(theta)
  return {
    {c, -s, 0, 0},
    {s, c, 0, 0},
    {0, 0, 1, 0},
    {0, 0, 0, 1}
  }
end

function mat4_scale(sx, sy, sz)
  return {
    {sx, 0,  0, 0},
    {0, sy,  0, 0},
    {0,  0, sz, 0},
    {0,  0,  0, 1},
  }
end

function mat4_perspective(fov, aspect, n, f)
  local t = 1/math.tan(fov/2)
  return {
    {t/aspect, 0, 0, 0},
    {0, t, 0, 0},
    {0, 0, (f+n)/(n-f), (2*f*n)/(n-f)},
    {0, 0, -1, 0}
  }
end

function mat4_lookat(eye, target, up)
  local zx, zy, zz = target[1]-eye[1], target[2]-eye[2], target[3]-eye[3]
  local len = math.sqrt(zx*zx + zy*zy + zz*zz)
  zx, zy, zz = zx/len, zy/len, zz/len

  local rx = up[2]*zz - up[3]*zy
  local ry = up[3]*zx - up[1]*zz
  local rz = up[1]*zy - up[2]*zx
  len = math.sqrt(rx*rx + ry*ry + rz*rz)
  rx, ry, rz = rx/len, ry/len, rz/len

  local ux = zy*rz - zz*ry
  local uy = zz*rx - zx*rz
  local uz = zx*ry - zy*rx

  return {
    {rx, ux, -zx, 0},
    {ry, uy, -zy, 0},
    {rz, uz, -zz, 0},
    {
      -(rx*eye[1] + ry*eye[2] + rz*eye[3]),
      -(ux*eye[1] + uy*eye[2] + uz*eye[3]),
      (zx*eye[1] + zy*eye[2] + zz*eye[3]),
      1
    }
  }
end

function projectVertices(v, M, P, width, height)
  local vWorld = mat4_mult_vec4(M, v)
  local near = 0.1
  if vWorld[3] < near then
    vWorld[3] = near
  end

  local vProj = mat4_mult_vec4(P, vWorld)
  local w = vProj[4]
  vProj[1] = vProj[1]/w
  vProj[2] = vProj[2]/w

  local sx = (vProj[1]*0.5 + 0.5) * width
  local sy = (-vProj[2]*0.5 + 0.5) * height
  return sx, sy
end


function clipLineNear(v1, v2)
  local z1, w1 = v1[3], v1[4]
  local z2, w2 = v2[3], v2[4]

  local t1 = (-w1 - z1) / ((z2 - z1) + (w2 - w1))
  if z1 >= -w1 and z2 >= -w2 then
    return v1, v2
  elseif z1 < -w1 and z2 < -w2 then
    return nil, nil
  elseif z1 < -w1 then
    local vNew = {}
    for i=1,4 do
      vNew[i] = v1[i] + t1*(v2[i]-v1[i])
    end
    return vNew, v2
  else
    local vNew = {}
    for i=1,4 do
      vNew[i] = v1[i] + t1*(v2[i]-v1[i])
    end
    return v1, vNew
  end
end

function love.load()
  cubeVertices = {
    vec4(-1,-1,-1), vec4(1,-1,-1), vec4(1,1,-1), vec4(-1,1,-1),
    vec4(-1,-1,1), vec4(1,-1,1), vec4(1,1,1), vec4(-1,1,1)
  }
  cubeEdges = {
    {1,2},{2,3},{3,4},{4,1},
    {5,6},{6,7},{7,8},{8,5},
    {1,5},{2,6},{3,7},{4,8}
  }
end

function CreateCube(tx, ty, tz, rx, ry, rz, sx, sy, sz)
  local w,h = love.graphics.getWidth(), love.graphics.getHeight()

  local M = mat4_mult(mat4_translation(tx, ty, tz), mat4_mult(mat4_rotate_x(rx), mat4_mult(mat4_rotate_y(ry), mat4_mult(mat4_rotate_z(rz), mat4_scale(sx, sy, sz)))))
  local V = mat4_lookat({0,0,3},{0,0,0},{0,1,0})
  local P = mat4_perspective(math.rad(90), w/h, 0.1, 100)
  local MV = mat4_mult(V,M)

  local screenVerts = {}
  for i,v in ipairs(cubeVertices) do
    local sx,sy = projectVertices(v, MV, P, w,h)
    screenVerts[i] = {sx,sy}
  end

  love.graphics.setColor(1,1,1)
  for _,e in ipairs(cubeEdges) do
    local v1,v2 = screenVerts[e[1]], screenVerts[e[2]]
    love.graphics.line(v1[1],v1[2],v2[1],v2[2])
  end
end

function love.update(dt)
  dt = math.min(dt,0.05)
end

function love.draw()
  -- example use ig :3
  CreateCube(0, 0, 5, 0, 34, 0, 1, 1, 1)
  CreateCube(0, -2, 5, 0, 50, 0, 1, 1, 1)
end

