# Instructions

To back up your Miniforge Conda environments, you can use the `conda env export` command to create YAML files that contain all the necessary information to recreate each environment. Here's how you can back up each of the environments listed:

1.  Navigate to the directory where you want to save your environment YAML files.
2.  Run the `conda env export` command for each environment and redirect the output to a YAML file. For example, to back up an environment called `CS50`, you would use:

    ```bash
    conda activate CS50 conda env export > CS50_environment.yml
    ```

    Repeat this for each environment, replacing `CS50` with the name of the environment and `CS50_environment.yml` with the corresponding file name you would want, like `FlaskKeyring_environment.yml`, `PyPassManager_environment.yml`, and `StockFolioHub_environment.yml`.

3.  After you have exported all the environments, deactivate the current environment:

    ```bash
    conda deactivate
    ```

4.  You should now have a set of YAML files (e.g., `CS50_environment.yml`, `FlaskKeyring_environment.yml`, etc.) in your chosen directory. These files contain all the necessary information to recreate your environments.

To recreate an environment from one of these YAML files on the same or another machine, use the following command:

    conda env create -f CS50_environment.yml

Replace `CS50_environment.yml` with the appropriate file name to recreate the other environments. This command will create a new Conda environment with the same name and install all the packages listed in the YAML file.
