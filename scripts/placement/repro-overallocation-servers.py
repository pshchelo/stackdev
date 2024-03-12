import subprocess
import sys
from multiprocessing import Pool
from time import sleep

from loguru import logger

"""
Reproduction script for race to consume the last inventory piece
https://bugs.launchpad.net/placement/+bug/2039560
using openstack CLI, needs a lot of adapting to local settings
"""

RESOURCE_PROVIDERS = [
    "538303f3-8d30-4e8d-b85b-c2ce74553df1",
    "5c86027d-6e93-4014-8483-3fa8eba83200",
    "51774919-3f7a-44de-b17a-d291f09ed69b",
]

# Define the commands you want to run in parallel
commands_info = {
    "create": "openstack server create --flavor m1.tiny_test --image Cirros-6.0.alt --net test-network --key test-key",
    "delete": "openstack server delete",
}


def check_nodes():
    logger.info("Checking nodes ...")
    sleep(2000)
    logger.info(run_command("openstack server list"))
    results = []
    is_reproduced = False
    invalid_provider = None
    for provider_id in RESOURCE_PROVIDERS:
        cmd = f"openstack resource provider usage show {provider_id} | grep CUSTOM_RESERVED_THREADS"
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        results.append(result.stdout)
        if result.stdout.startswith("| CUSTOM_RESERVED_THREADS |    96 |"):
            is_reproduced = True
            invalid_provider = provider_id

    if is_reproduced:
        output = "\n".join(results)
        raise Exception(f"The bug has been reproduced:\n{output}\nprovider: {invalid_provider}")


def run_command(cmd):
    try:
        logger.info(f"Running command: {cmd}")
        result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if result.returncode != 0:
            logger.error(f"Command '{cmd}' failed with error:\n{result.stderr}")
        return result.stdout
    except Exception as e:
        logger.error(f"Error running command '{cmd}': {str(e)}")


def servers():
    return " ".join(run_command("openstack server list -c ID -f value").splitlines())


if __name__ == "__main__":
    instances = 6
    try:
        number_of_iterations = sys.argv[1]
    except IndexError:
        logger.info("Cleaning up instances ...")
        run_command(f"{commands_info['delete']} {servers()}")
    else:
        try:
            number_of_iterations = int(number_of_iterations)
            for i in range(number_of_iterations):
                logger.info(f"Iteration {i + 1}:")
                # while True:
                logger.info(f"Scheduling instances {instances} ...")
                commands = [f"{commands_info['create']} test-server-{count + 1}" for count in range(instances)]
                with Pool(instances) as pool:
                    pool.map(run_command, commands)

                check_nodes()

                logger.info("Cleaning up instances ...")
                run_command(f"{commands_info['delete']} {servers()}")

            logger.info(f"The bug hasn't been reproduced on {number_of_iterations} iterations.")
        except ValueError:
            for i in range(instances + 1):
                run_command(f"{commands_info['create']} test-server-{i + 1}")
