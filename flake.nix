{
  description = "Flake for development workflows.";

  inputs = {
    rainix.url = "github:rainlanguage/rainix/31fb1fa967bbfc484526101de9dc85e36a2530b9";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {self, flake-utils, rainix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = rainix.pkgs.${system};
      in rec {
        packages = rec {

          tauri-release-env = rainix.tauri-release-env.${system};

          ob-tauri-prelude = rainix.mkTask.${system} {
            name = "ob-tauri-prelude";
            body = ''
              set -euxo pipefail

              # Generate Typescript types from rust types
              mkdir -p tauri-app/src/lib/typeshare;

              typeshare crates/subgraph/src/types/vault_balance_changes_list.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/vaultBalanceChangesList.ts;
              typeshare crates/subgraph/src/types/vault_balance_change.rs --lang=typescript --output-file=/tmp/vaultBalanceChange.ts;
              cat /tmp/vaultBalanceChange.ts >> tauri-app/src/lib/typeshare/vaultBalanceChangesList.ts;

              typeshare crates/subgraph/src/types/order_detail.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/orderDetail.ts;
              typeshare crates/common/src/types/order_detail_extended.rs --lang=typescript --output-file=/tmp/orderDetailExtended.ts
              cat /tmp/orderDetailExtended.ts >> tauri-app/src/lib/typeshare/orderDetail.ts;

              typeshare crates/subgraph/src/types/vault_detail.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/vaultDetail.ts;
              typeshare crates/subgraph/src/types/vaults_list.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/vaultsList.ts;
              typeshare crates/subgraph/src/types/orders_list.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/ordersList.ts;
              typeshare crates/subgraph/src/types/order_takes_list.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/orderTakesList.ts;
              typeshare crates/subgraph/src/types/order_take_detail.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/orderTakeDetail.ts;

              typeshare crates/settings/src/parse.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/appSettings.ts;

              typeshare tauri-app/src-tauri/src/toast.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/toast.ts;
              typeshare tauri-app/src-tauri/src/transaction_status.rs --lang=typescript --output-file=tauri-app/src/lib/typeshare/transactionStatus.ts;

              # Fix linting of generated types
              cd tauri-app && npm i && npm run lint
            '';
            additionalBuildInputs = [
              pkgs.typeshare
              pkgs.wasm-bindgen-cli
              rainix.rust-toolchain.${system}
              rainix.rust-build-inputs.${system}
            ];
          };
          ob-tauri-test =  rainix.mkTask.${system} {
            name = "ob-tauri-test";
            body = ''
              set -euxo pipefail

              cd tauri-app && npm i && npm run test
            '';
          };

          update-bin = rainix.mkTask.${system} {
            name = "update-bin";
            body = ''
              set -euxo pipefail

              ls src-tauri/target/release
              otool -L src-tauri/target/release/demo
            '';
          };

          update-libs = rainix.mkTask.${system} {
            name = "update-libs";
            body = ''
              set -euxo pipefail

              rm -rf lib
              mkdir -p lib

              cp ${pkgs.gettext}/lib/libintl.8.dylib lib/libintl.8.dylib
              chmod +w lib/libintl.8.dylib
              install_name_tool -id @executable_path/../Frameworks/libintl.8.dylib lib/libintl.8.dylib

              cp ${pkgs.libiconv}/lib/libiconv.dylib lib/libiconv.dylib
              chmod +w lib/libiconv.dylib
              install_name_tool -id @executable_path/../Frameworks/libiconv.dylib lib/libiconv.dylib
              install_name_tool -change ${pkgs.libiconv}/lib/libiconv.dylib @executable_path/../Frameworks/libiconv.dylib lib/libintl.8.dylib

              cp ${pkgs.libiconv}/lib/libiconv-nocharset.dylib lib/libiconv-nocharset.dylib
              chmod +w lib/libiconv-nocharset.dylib
              install_name_tool -id @executable_path/../Frameworks/libiconv-nocharset.dylib lib/libiconv-nocharset.dylib
              install_name_tool -change ${pkgs.libiconv}/lib/libiconv-nocharset.dylib @executable_path/../Frameworks/libiconv-nocharset.dylib lib/libiconv.dylib

              cp ${pkgs.libiconv}/lib/libcharset.1.dylib lib/libcharset.1.dylib
              chmod +w lib/libcharset.1.dylib
              install_name_tool -id @executable_path/../Frameworks/libcharset.1.dylib lib/libcharset.1.dylib
              install_name_tool -change ${pkgs.libiconv}/lib/libcharset.1.dylib @executable_path/../Frameworks/libcharset.1.dylib lib/libiconv.dylib
            '';
          };
        } // rainix.packages.${system};

        devShells.default = rainix.devShells.${system}.default;
        devShells.tauri-shell = pkgs.mkShell {
          packages = [
            packages.ob-tauri-prelude
            packages.ob-tauri-test
            packages.update-libs
            packages.update-bin
          ];
          inputsFrom = [ rainix.devShells.${system}.tauri-shell ];
        };

      }
    );

}
