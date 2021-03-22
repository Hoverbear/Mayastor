{ stdenv
, clang
, dockerTools
, e2fsprogs
, lib
, libaio
, libiscsi
, libspdk
, libspdk-dev
, libudev
, liburing
, llvmPackages
, rustPlatform
, numactl
, openssl
, pkg-config
, protobuf
, xfsprogs
, utillinux
, llvmPackages_11
, targetPackages
, buildPackages
, targetPlatform
, pkgs
}:
let
  version = (builtins.fromTOML (builtins.readFile ../../../mayastor/Cargo.toml)).package.version;
  project-builder = pkgs.callPackage ./cargo-package.nix { inherit version; };
in
{
  release = project-builder.release;
  debug = project-builder.debug;
  adhoc = project-builder.adhoc;
}
