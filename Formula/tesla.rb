class Tesla < Formula
  desc "Temporal assertions with static analysis"
  homepage "http://baltoli.github.io"
  head "https://github.com/cadets/tesla-static-analysis.git"

  depends_on "cmake" => :build
  depends_on "llvm"
  depends_on "z3"
  depends_on "protobuf"

  def install
    # ENV.deparallelize  # if your formula fails when building in parallel

    cmake_args = ["-DLLVM_DIR=#{Formula["llvm"].opt_lib}/cmake/llvm",
                  "-DCMAKE_INCLUDE_PATH=#{Formula["protobuf"].opt_include}"]

    mkdir "build" do
      system "cmake", "..", *cmake_args, *std_cmake_args
      system "make", "install" # if this fails, try separate make/make install steps
    end
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test tesla-static-analysis`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end
end
