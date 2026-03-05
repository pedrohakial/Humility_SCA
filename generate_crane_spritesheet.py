
import math
import os
import json
from PIL import Image, ImageDraw

# Use relative paths or workspace paths
PARTS_DIR = "/Users/smmdopnp/Downloads/crane_parts"
METADATA_PATH = os.path.join(PARTS_DIR, "crane_metadata.json")
OUTPUT_PATH = "/Users/smmdopnp/dev/godot/crane_spritesheet.png"

def main():
    if not os.path.exists(METADATA_PATH):
        print(f"Error: Metadata not found at {METADATA_PATH}")
        return

    with open(METADATA_PATH, 'r') as f:
        meta = json.load(f)

    # Load images
    base_img = Image.open(os.path.join(PARTS_DIR, "crane_base.png")).convert("RGBA")
    arm_img = Image.open(os.path.join(PARTS_DIR, "crane_arm.png")).convert("RGBA")
    hook_img = Image.open(os.path.join(PARTS_DIR, "crane_hook.png")).convert("RGBA")

    # Pivot points and offsets from metadata
    arm_pivot_orig = meta['godot_setup']['arm_pivot_in_original'] # [130, 116]
    arm_offset = meta['parts']['arm']['offset_in_original'] # [10, 0]
    arm_pivot_local = meta['parts']['arm']['pivot_local'] # [120, 116]
    
    base_offset = meta['parts']['base']['offset_in_original'] # [20, 110]
    
    hook_offset_orig = meta['parts']['hook']['offset_in_original'] # [33, 174]
    hook_attach_local = meta['parts']['hook']['attach_point_local'] # [7, 2]
    
    # In original coords, the boom end is roughly at (40, 50)
    arm_chain_start_orig = (40, 50) 
    arm_chain_start_local = (arm_chain_start_orig[0] - arm_offset[0], arm_chain_start_orig[1] - arm_offset[1])

    total_frames = 16
    cols = 4
    rows = 4
    
    # Frame size (large enough to fit all parts and movement)
    fw, fh = 200, 240
    
    frames = []

    for i in range(total_frames):
        frame = Image.new("RGBA", (fw, fh), (0, 0, 0, 0))
        
        # Determine animation phase
        if i < 4: # Phase 1: Arm swings outward, hook descends
            t = i / 4.0
            arm_rot = -12 * t
            hook_ext = 50 * t
            sway = 0
        elif i < 8: # Phase 2: Hook at lowest point with gentle sway
            t = (i - 4) / 4.0
            arm_rot = -12
            hook_ext = 50
            sway = 6 * math.sin(t * math.pi * 2)
        elif i < 12: # Phase 3: Arm pulls back, hook ascends
            t = (i - 8) / 4.0
            arm_rot = -12 * (1 - t)
            hook_ext = 50 * (1 - t)
            sway = 3 * math.sin(t * math.pi * 2)
        else: # Phase 4: Settles back to rest position
            t = (i - 12) / 4.0
            arm_rot = 2 * math.sin(t * math.pi * 2) * math.exp(-t * 2)
            hook_ext = 0
            sway = 1 * math.sin(t * math.pi * 2) * math.exp(-t * 2)

        # Pivot position in frame (centered horizontally, middle-low vertically)
        px, py = fw // 2 + 20, fh // 2

        # Draw Base
        bx = px - (arm_pivot_orig[0] - base_offset[0])
        by = py - (arm_pivot_orig[1] - base_offset[1])
        frame.paste(base_img, (int(bx), int(by)), base_img)

        # Rotate Arm
        arm_canvas_size = max(arm_img.width, arm_img.height) * 2
        arm_canvas = Image.new("RGBA", (arm_canvas_size, arm_canvas_size), (0, 0, 0, 0))
        acp = arm_canvas_size // 2
        arm_canvas.paste(arm_img, (acp - arm_pivot_local[0], acp - arm_pivot_local[1]), arm_img)
        rotated_arm = arm_canvas.rotate(arm_rot, resample=Image.BICUBIC, center=(acp, acp))
        frame.paste(rotated_arm, (px - acp, py - acp), rotated_arm)

        # Chain start on rotated arm
        rad = math.radians(-arm_rot)
        dx = arm_chain_start_local[0] - arm_pivot_local[0]
        dy = arm_chain_start_local[1] - arm_pivot_local[1]
        rot_dx = dx * math.cos(rad) - dy * math.sin(rad)
        rot_dy = dx * math.sin(rad) + dy * math.cos(rad)
        csx, csy = px + rot_dx, py + rot_dy
        
        # Hook attach point
        hax = csx + sway
        hay = csy + 40 + hook_ext # 40 is base chain length
        
        # Draw Chain
        draw = ImageDraw.Draw(frame)
        draw.line([(csx, csy), (hax, hay)], fill=(60, 60, 60, 255), width=1)
        
        # Draw Hook
        hx = int(hax - hook_attach_local[0])
        hy = int(hay - hook_attach_local[1])
        frame.paste(hook_img, (hx, hy), hook_img)
        
        frames.append(frame)

    # Assemble sheet
    sheet = Image.new("RGBA", (fw * cols, fh * rows), (0, 0, 0, 0))
    for idx, f in enumerate(frames):
        c, r = idx % cols, idx // cols
        sheet.paste(f, (c * fw, r * fh))
        
    sheet.save(OUTPUT_PATH)
    print(f"Successfully generated sprite sheet: {OUTPUT_PATH}")

if __name__ == "__main__":
    main()
