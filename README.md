# Modules Manager for ODFI

This is the entry point for ODFI modules.
Use this module to manage an ODFI installation

# Usage

# Behind the curtain

## Installation Structure

The basic installation of ODFI follows this structure:

- This module manager is located on a central server
	- Admin can use utilities to update modules from git repositories
- Users can source it's setup from any machine to have access to installed modules
	- The modules manager can check the local machine for compatibility

## Developer Workflow in shared installation

If a developer wants to edit an ODFI module, and there is a central odfi installation:

- The module manager can work hierarchically
- A user can install a module manager for itself, which will reference the central one, to keep the normal central installation working
- Then the user can checkout a module in its local module manager
- The checked out module is then "overriding" the central installation

## Module Manager implementation

This manager is an entry point to the system, meaning it shouldn't have complex dependencies,
or impose some for the installation.

Typically, that would mean we should stick to basic scripting (like bash), but then it becomes more difficult to support more various systems, and complex helpful usage scenarios

The approach chosen is to implement the module manager like this:

- Implement all functions using TCL scripting
	- TCL is wildly supported and since a very long time, so we should get it working on all systems
- The module manager can have some dependencies for itself, but will never modify installed modules environment
- Have system dependent "low level" scripting/software to bootstrap module manager dependencies like TCL

## Folder Structure

- private/ : Contains dependencies and stuff only used by and for module manager
- install/ : Contains the installed modules. This is the odfi installation


# Hierarchical Install

ODFI Module manager can work hierarchically, which means that it can load installed modules from one or more other installations


# Extending available modules configuration

# Config Files Reference

## odfi.*.config

This is the local manager configuration file.
The content of those files are executed on the target installation configuration in the listing order, so beware of overridings!

Here are the available configuration constructs:

- parent "/path/to/other/manager"

This references the path to another manager base folder or config file
The local manager will load modules definitions and installed modules from the parent manager
