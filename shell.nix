{ mkShell, swift, swiftpm, swiftpm2nix }:

mkShell {
  buildInputs = [
    swift
    swiftpm
    swiftpm2nix
  ];
}