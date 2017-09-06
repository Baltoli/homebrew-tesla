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
  url "https://github.com/cadets/tesla-static-analysis/releases/download/v0.2-pre/tesla-0.2.tar.gz"
  sha256 "3bf0fb926f64192cf39dde7fb5621041fcd6c5fc3ba0a3cd4715aa6f0fc59d73"
  head "https://github.com/cadets/tesla-static-analysis.git"

  depends_on "cmake" => :build
  depends_on "llvm"
  depends_on "z3"
  depends_on "protobuf"

  bottle do
    root_url "https://github.com/cadets/tesla-static-analysis/releases/download/v0.2-pre/"
    sha256 "d70827514f705ee32aa92261c742506461e94416ac4fc3b9a9510bb75c72289f" => :sierra
  end

  def install
    cmake_args = ["-DLLVM_DIR=#{Formula["llvm"].lib}/cmake/llvm",
                  "-DCMAKE_INCLUDE_PATH=#{Formula["protobuf"].include}"]

    mkdir "build" do
      system "cmake", "..", *cmake_args, *std_cmake_args
      system "make", "install"
    end
  end

  test do
    ENV["OPT"] = "#{Formula["llvm"].bin}/opt"
    TESLA = "#{bin}/tesla".freeze
    CLANG = "#{Formula["llvm"].bin}/clang".freeze
    (testpath/"test.c").write(TEST_C)

    system TESLA, "analyse", (testpath/"test.c"), "-o", "test.tesla", "--"
    system TESLA, "cat", "test.tesla", "-o", "test.manifest"
    system CLANG, "-c", "-emit-llvm", "-o", "test.bc", (testpath/"test.c")
    system TESLA, "instrument", "-tesla-manifest=test.manifest", "test.bc", "-o", "test.instr.bc"
    system CLANG, "test.instr.bc", "-ltesla", "-o", "test"
    system "./test"

    system TESLA, "static", "-tesla-manifest=test.manifest", "test.bc"
    system TESLA, "instrument", "-tesla-manifest=test.manifest", "test.bc", "-o", "test.static.instr.bc"
    system CLANG, "test.static.instr.bc", "-ltesla", "-o", "test.static"
    system "./test.static"
  end
end
