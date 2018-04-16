from os import path, rename, remove
import sys, logging
import subprocess, argparse

import_status = False
try:
    from PIL import Image, ImageFilter
except ImportError:
    print("Pillow module not found! Cubemaps won't be blurred.\n")
else:
    import_status = True

dir_path = (path.abspath(path.dirname(__file__)))
texass_path = (path.abspath(path.dirname(__file__)) + "\\texassemble.exe ")
texconv_path = (path.abspath(path.dirname(__file__)) + "\\texconv.exe ")

args = sys.argv[1:]
temp = "\\temp\\"

def get_args(args_v):
    parser = argparse.ArgumentParser(description='Assembles cube faces into a cubemap with a .texture format')
    parser.add_argument("type", 
                        help = "first arg has to be either reflect or lights",
                        choices = ["reflect", "light"])
    parser.add_argument("-i", help = "imput 6 filenames for each cube face", nargs = "*")
    parser.add_argument("-o", help = "output filename")
    
    args = parser.parse_args(args_v)

    if not args.type:
        logging.warning("[ERROR] Incorrect argument specified")
        sys.exit(1)

    return args.type, args.i, args.o

def move_and_rename_cubemap(cubemap_name):
    cubemap_path = path.abspath("") + "\\"
    print(cubemap_path + cubemap_name)
    cubemap_name_new = cubemap_name[:-4] + ".texture"
    
    if not path.isfile(dir_path + temp + cubemap_name_new):
        rename(cubemap_path + cubemap_name, dir_path + temp + cubemap_name_new)
    if path.isfile(dir_path + temp + cubemap_name):
        remove(dir_path + temp + cubemap_name)
    sys.exit(0)

def fix_paths(input_args, output_arg):
    input_paths = []
    if output_arg: 
        output_paths = ["-o", dir_path + temp + output_arg]
    for file in input_args:
        input_paths.append(dir_path + temp + file)
    return input_paths, output_paths

def start_process(proc_path, input):
    input.insert(0, proc_path)
    proc = subprocess.Popen(input, stdout=subprocess.PIPE)

    output, _ = proc.communicate()
    output = output.decode("utf-8", "ignore")
    
    print(output)
    logging.info(output)

    if str.find(output, "ERROR") != -1 or str.find(output, "Failed") != -1:
        logging.error(proc_path + " finished with an error!")
        sys.exit(1)

def convert_cubemaps(output_path, argtype):
    if argtype == "reflect":
        args = ["-m", "10", "-f", "BC2_UNORM", "-y"]
    else:
        args = ["-m", "8", "-f", "BC3_UNORM", "-y"]
    output_path.remove("-o")    # for some reason it always fails to write if I specify output
    args.extend(output_path)
    start_process(texconv_path, args)

def generate_cubemaps(files, output_path):
    s = ["cube"]
    for filename in files:
        s.append(filename)
    s.extend(output_path)
    s.append("-y")
    print(s)
    start_process(texass_path, s)

def blur_cubes(files):
    if import_status:
        for cube in files:
            print(cube)
            img = Image.open(cube)
            processed = img.filter(ImageFilter.GaussianBlur(radius=3))
            processed.show()
            processed.save(cube)

if __name__ == "__main__":
    argtype, input, output = get_args(args[:])
    logging.basicConfig(filename=dir_path + "\\cubemapgen.log" ,level=logging.INFO)
    
    cube_paths, cubemap_path = fix_paths(input, output)
    blur_cubes(cube_paths)
    generate_cubemaps(cube_paths, cubemap_path)
    convert_cubemaps(cubemap_path, argtype)
    move_and_rename_cubemap(output)