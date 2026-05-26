#!.venv/bin/python3
#######################################################################
# Create zip file for function code and dependencies
# - create dependencies if requirements.txt changed
# - create zip file with code from src and dependencies
#
# The zip file will have the following structure:
# .
# ├── src
# │   ├── FILE1.py
# │   └── ...
# └── <installed packages from requirements.txt> 
#
#######################################################################
import os
import subprocess
import hashlib
import shutil

from zipfile import ZIP_DEFLATED, ZipFile


TARGET_FOLDER = "./target"
OUTPUT_ZIP = f"{TARGET_FOLDER}/code.zip"
ZIP_HASH_FILE = f"{TARGET_FOLDER}/.zip_hash"

REQUIREMENTS_FILE = "./requirements.txt"
REQUIREMENTS_HASH_FILE = f"{TARGET_FOLDER}/.requirements_hash"

DEPENDENCIES = "dependencies"
DEPENDENCIES_FOLDER = f"{TARGET_FOLDER}/{DEPENDENCIES}"


####################################################################
# Zip Code and dependencies
####################################################################
def createZippedFunctionCode():
    requirements_hash = hashlib.md5(open(REQUIREMENTS_FILE, "rb").read()).hexdigest()
    OLD_requirements_hash = ""
    if os.path.exists(REQUIREMENTS_HASH_FILE):
        with open(REQUIREMENTS_HASH_FILE, "r") as f:
            OLD_requirements_hash = f.read().strip()

    if requirements_hash != OLD_requirements_hash:
        print(f"Changes in {REQUIREMENTS_FILE} - updating dependencies")

        shutil.rmtree(TARGET_FOLDER, ignore_errors=True)

        os.makedirs(DEPENDENCIES_FOLDER, exist_ok=True)
        # create dependencies
        p = subprocess.run(
            [f"python3 -m pip install -t {DEPENDENCIES_FOLDER} --platform linux_x86_64 --only-binary=:all: -r {REQUIREMENTS_FILE}"],
            shell=True,
        )

        if p.returncode != 0:
            print(f"Error installing dependencies, returncode {p.returncode}")
            exit(p.returncode)

        # write new hash
        with open(REQUIREMENTS_HASH_FILE, "w") as f:
            f.write(requirements_hash)

    else:
        print(f"No changes in {REQUIREMENTS_FILE} - skip updating dependencies")


    CURRENT_FOLDER=os.getcwd()
    print(f"Current folder: {CURRENT_FOLDER}")
    
    with ZipFile(OUTPUT_ZIP, "w", ZIP_DEFLATED) as zip:
        # add files from folder src
        src = "./src"
        for dirname, subdirs, files in os.walk(src):
            for filename in files:
                absname = os.path.abspath(os.path.join(dirname, filename))
                arcname = absname[absname.rindex(f"{CURRENT_FOLDER}") + len(f"{CURRENT_FOLDER}") :]
                # print("zipping %s as %s" % (os.path.join(dirname, filename), arcname))
                if (
                     "__pycache__" not in absname 
                     and "__pycache__" not in arcname
                     and "bootstrap" not in arcname
                ):
                    #print("zipping %s as %s" % (os.path.join(dirname, filename), arcname))
                    zip.write(absname, arcname)

        # add files from dependencies
        FULL_DEPENDENCIES_FOLDER=f"{CURRENT_FOLDER}/target/{DEPENDENCIES}"
        for dirname, subdirs, files in os.walk(DEPENDENCIES_FOLDER):
            for filename in files:
                absname = os.path.abspath(os.path.join(dirname, filename))
                arcname = absname[
                    # remove all parent folder names from absname
                    absname.rindex(f"{FULL_DEPENDENCIES_FOLDER}/") + len(f"{FULL_DEPENDENCIES_FOLDER}/") :
                ]
                # arcname = f"dependencies/{arcname}"                
                # put all dependencies to root of zip file
                arcname = f"{arcname}"
                if (
                    #not arcname.startswith("pip") and
                    not arcname.startswith("_distutils")
                    and not arcname.startswith("setuptools")
                    #and ".dist-info" not in absname
                    and "__pycache__" not in absname
                    and "__pycache__" not in arcname
                ):
                    #print("zipping %s as %s      --- %s"  % (os.path.join(dirname, filename), arcname, absname))
                    zip.write(absname, arcname)
                    
        zip.write("./README.md", "README.md")
    
    print(f"created: {OUTPUT_ZIP}")
    
    zip_hash = hashlib.md5(open(OUTPUT_ZIP, "rb").read()).hexdigest()
    
    with open(ZIP_HASH_FILE, "w") as f:
            f.write(zip_hash)


if __name__ == "__main__":
    createZippedFunctionCode()
