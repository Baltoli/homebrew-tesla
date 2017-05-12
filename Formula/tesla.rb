TEST_C = <<-HERE
#include <tesla-macros.h>

int main(void);
void foo(void);

void bar(void) {
  TESLA_WITHIN(main, previously(
    call(foo)
  ));
}

void foo(void) {
  TESLA_WITHIN(main, eventually(
    call(bar)
  ));
}

int main(void) {
  foo();
  bar();
}
HERE
         .freeze

class Tesla < Formula
  desc "Temporal assertions with static analysis"
  homepage "https://baltoli.github.io"
  url "https://github.com/cadets/tesla-static-analysis/releases/download/v0.1-pre/tesla-0.1.tar.gz"
  sha256 "d229bc948cde193ebb227130317b9d2ab5061ad09e5c241244f4100fb74e1072"
  head "https://github.com/cadets/tesla-static-analysis.git"

  depends_on "cmake" => :build
  depends_on "llvm"
  depends_on "z3"
  depends_on "protobuf"

  def install
    cmake_args = ["-DLLVM_DIR=#{Formula["llvm"].lib}/cmake/llvm",
                  "-DCMAKE_INCLUDE_PATH=#{Formula["protobuf"].include}"]

    mkdir "build" do
      system "cmake", "..", *cmake_args, *std_cmake_args
      system "make", "install"
    end
  end

  test do
    TESLA = "#{bin}/tesla".freeze
    CLANG = "#{Formula["llvm"].bin}/clang".freeze
    (testpath/"test.c").write(TEST_C)

    system TESLA, "analyse", (testpath/"test.c"), "-o", "test.tesla", "--"
    system TESLA, "cat", "test.tesla", "-o", "test.manifest"
    system CLANG, "-c", "-emit-llvm", "-o", "test.bc", (testpath/"test.c")
    system TESLA, "instrument", "-tesla-manifest", "test.manifest", "test.bc", "-o", "test.instr.bc"
    system CLANG, "test.instr.bc", "-ltesla", "-o", "test"
    system "./test"

    system TESLA, "static", "test.manifest", "test.bc", "-mc", "-bound=10", "-o", "test.static.manifest"
    system TESLA, "instrument", "-tesla-manifest", "test.static.manifest", "test.bc", "-o", "test.static.instr.bc"
    system CLANG, "test.static.instr.bc", "-ltesla", "-o", "test.static"
    system "./test.static"
  end
end
