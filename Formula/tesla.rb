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

class Tesla < Formula
  desc "Temporal assertions with static analysis"
  homepage "http://baltoli.github.io"
  head "https://github.com/cadets/tesla-static-analysis.git"

  depends_on "cmake" => :build
  depends_on "llvm" => "with-clang"
  depends_on "z3"
  depends_on "protobuf"

  def install
    cmake_args = ["-DLLVM_DIR=#{Formula["llvm"].opt_lib}/cmake/llvm",
                  "-DCMAKE_INCLUDE_PATH=#{Formula["protobuf"].opt_include}"]

    mkdir "build" do
      system "cmake", "..", *cmake_args, *std_cmake_args
      system "make", "install"
    end
  end

  test do
    TESLA = "#{bin}/tesla"
    CLANG = "#{Formula["llvm"].opt_bin}/clang"
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
