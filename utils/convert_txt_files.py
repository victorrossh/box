import json
import os

# Folder containing your JSON files
folder_path = "Box"  # Change this to your folder path
output_file = "insert_boxes.sql"

insert_statements = []

# Iterate through all files in the folder
for filename in os.listdir(folder_path):
    if filename.endswith(".json"):
        map_name = os.path.splitext(filename)[0]  # Remove .json extension for map name
        file_path = os.path.join(folder_path, filename)
        
        # Load JSON data
        with open(file_path, "r") as f:
            data = json.load(f)
        
        # Generate INSERT statements for each box
        for box in data:
            sql = f"""
INSERT INTO box 
    (map, type, box_id, origin_x, origin_y, origin_z, mins_x, mins_y, mins_z, maxs_x, maxs_y, maxs_z)
VALUES
    ('{map_name}', '{box['Type']}', '{box['Id']}', 
    {box['Origin']['X']:.2f}, {box['Origin']['Y']:.2f}, {box['Origin']['Z']:.2f}, 
    {box['Mins']['X']:.2f}, {box['Mins']['Y']:.2f}, {box['Mins']['Z']:.2f}, 
    {box['Maxs']['X']:.2f}, {box['Maxs']['Y']:.2f}, {box['Maxs']['Z']:.2f});
"""
            insert_statements.append(sql.strip())

# Write all INSERT statements to a file
with open(output_file, "w") as f:
    f.write("\n".join(insert_statements))

print(f"INSERT statements generated successfully in '{output_file}'.")
