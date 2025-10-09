#!/bin/bash
# High-Frequency Trading System with FPGA Acceleration
# Comprehensive Test Suite Runner
# Usage: ./run_tests.sh [options]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
BUILD_DIR="${BUILD_DIR:-../build}"
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$TEST_DIR")"
LOG_DIR="${ROOT_DIR}/logs/tests"

# Test options
RUN_UNIT_TESTS=true
RUN_INTEGRATION_TESTS=false
RUN_FPGA_TESTS=false
RUN_PERFORMANCE_TESTS=false
RUN_COVERAGE=false
VERBOSE=false
QUICK_MODE=false

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run test suite for HFT FPGA System

Options:
    -a, --all           Run all tests (unit, integration, FPGA, performance)
    -u, --unit          Run unit tests only (default)
    -i, --integration   Run integration tests
    -f, --fpga          Run FPGA hardware tests (requires FPGA)
    -p, --performance   Run performance benchmarks
    -c, --coverage      Generate code coverage report
    -q, --quick         Quick mode (skip slow tests)
    -v, --verbose       Verbose output
    -h, --help          Show this help message

Examples:
    $0                  # Run unit tests
    $0 -a               # Run all tests
    $0 -u -c            # Run unit tests with coverage
    $0 -i -v            # Run integration tests with verbose output

EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            RUN_UNIT_TESTS=true
            RUN_INTEGRATION_TESTS=true
            RUN_FPGA_TESTS=true
            RUN_PERFORMANCE_TESTS=true
            shift
            ;;
        -u|--unit)
            RUN_UNIT_TESTS=true
            shift
            ;;
        -i|--integration)
            RUN_INTEGRATION_TESTS=true
            shift
            ;;
        -f|--fpga)
            RUN_FPGA_TESTS=true
            shift
            ;;
        -p|--performance)
            RUN_PERFORMANCE_TESTS=true
            shift
            ;;
        -c|--coverage)
            RUN_COVERAGE=true
            shift
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Print functions
print_header() {
    echo -e "\n${BLUE}==========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}==========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Setup test environment
setup_test_environment() {
    print_header "Setting Up Test Environment"
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Check if build directory exists
    if [ ! -d "$BUILD_DIR" ]; then
        print_error "Build directory not found: $BUILD_DIR"
        print_info "Please build the project first: mkdir build && cd build && cmake .. && make"
        exit 1
    fi
    
    # Change to build directory
    cd "$BUILD_DIR"
    
    print_success "Test environment ready"
}

# Run unit tests
run_unit_tests() {
    print_header "Running Unit Tests"
    
    local test_filter="*"
    if [ "$QUICK_MODE" = true ]; then
        test_filter="*Quick*:*Fast*"
        print_info "Quick mode: Running fast tests only"
    fi
    
    local test_args="--gtest_filter=$test_filter"
    if [ "$VERBOSE" = true ]; then
        test_args="$test_args --gtest_print_time=1"
    fi
    
    # Run unit tests with CTest
    if ctest -R "unit_" -V --output-on-failure; then
        print_success "Unit tests passed"
        ((PASSED_TESTS++))
    else
        print_error "Unit tests failed"
        ((FAILED_TESTS++))
        return 1
    fi
    
    ((TOTAL_TESTS++))
}

# Run integration tests
run_integration_tests() {
    print_header "Running Integration Tests"
    
    if [ ! -f "$BUILD_DIR/tests/integration_tests" ]; then
        print_warning "Integration tests not built, skipping"
        ((SKIPPED_TESTS++))
        return 0
    fi
    
    # Run integration tests with CTest
    if ctest -R "integration_" -V --output-on-failure; then
        print_success "Integration tests passed"
        ((PASSED_TESTS++))
    else
        print_error "Integration tests failed"
        ((FAILED_TESTS++))
        return 1
    fi
    
    ((TOTAL_TESTS++))
}

# Run FPGA tests
run_fpga_tests() {
    print_header "Running FPGA Hardware Tests"
    
    # Check if FPGA is available
    if ! command -v xbutil &> /dev/null; then
        print_warning "XRT tools not found, skipping FPGA tests"
        ((SKIPPED_TESTS++))
        return 0
    fi
    
    # Check FPGA device
    if ! xbutil examine &> /dev/null; then
        print_warning "No FPGA device detected, skipping FPGA tests"
        ((SKIPPED_TESTS++))
        return 0
    fi
    
    if [ ! -f "$BUILD_DIR/tests/fpga_tests" ]; then
        print_warning "FPGA tests not built, skipping"
        ((SKIPPED_TESTS++))
        return 0
    fi
    
    # Run FPGA tests with CTest
    if sudo ctest -R "fpga_" -V --output-on-failure; then
        print_success "FPGA tests passed"
        ((PASSED_TESTS++))
    else
        print_error "FPGA tests failed"
        ((FAILED_TESTS++))
        return 1
    fi
    
    ((TOTAL_TESTS++))
}

# Run performance tests
run_performance_tests() {
    print_header "Running Performance Benchmarks"
    
    if [ ! -f "$BUILD_DIR/benchmarks/performance_benchmark" ]; then
        print_warning "Performance benchmarks not built, skipping"
        ((SKIPPED_TESTS++))
        return 0
    fi
    
    local benchmark_args="--benchmark_format=console"
    if [ "$VERBOSE" = true ]; then
        benchmark_args="$benchmark_args --benchmark_display_aggregates_only=false"
    fi
    
    if [ "$QUICK_MODE" = true ]; then
        benchmark_args="$benchmark_args --benchmark_filter=Quick"
    fi
    
    # Run performance benchmarks
    if ./benchmarks/performance_benchmark $benchmark_args; then
        print_success "Performance benchmarks completed"
        ((PASSED_TESTS++))
    else
        print_error "Performance benchmarks failed"
        ((FAILED_TESTS++))
        return 1
    fi
    
    ((TOTAL_TESTS++))
}

# Generate coverage report
generate_coverage() {
    print_header "Generating Code Coverage Report"
    
    if ! command -v lcov &> /dev/null; then
        print_warning "lcov not installed, skipping coverage report"
        print_info "Install with: sudo apt-get install lcov"
        return 0
    fi
    
    local coverage_dir="$BUILD_DIR/coverage"
    mkdir -p "$coverage_dir"
    
    # Capture coverage data
    print_info "Capturing coverage data..."
    lcov --capture --directory . --output-file "$coverage_dir/coverage.info" 2>&1 | grep -v "ignoring data for external file"
    
    # Filter out system files and test files
    lcov --remove "$coverage_dir/coverage.info" \
        '/usr/*' \
        '*/tests/*' \
        '*/test/*' \
        '*/third_party/*' \
        --output-file "$coverage_dir/coverage_filtered.info"
    
    # Generate HTML report
    print_info "Generating HTML report..."
    genhtml "$coverage_dir/coverage_filtered.info" \
        --output-directory "$coverage_dir/html" \
        --title "HFT FPGA System Coverage" \
        --legend --quiet
    
    # Print summary
    lcov --summary "$coverage_dir/coverage_filtered.info"
    
    print_success "Coverage report generated: $coverage_dir/html/index.html"
}

# Print test summary
print_summary() {
    print_header "Test Summary"
    
    echo "Total test suites: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo -e "${YELLOW}Skipped: $SKIPPED_TESTS${NC}"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "\n${GREEN}All tests passed! ✓${NC}\n"
        return 0
    else
        echo -e "\n${RED}Some tests failed! ✗${NC}\n"
        return 1
    fi
}

# Main execution
main() {
    print_header "HFT FPGA System Test Suite"
    
    # Setup
    setup_test_environment
    
    # Run selected tests
    if [ "$RUN_UNIT_TESTS" = true ]; then
        run_unit_tests || true
    fi
    
    if [ "$RUN_INTEGRATION_TESTS" = true ]; then
        run_integration_tests || true
    fi
    
    if [ "$RUN_FPGA_TESTS" = true ]; then
        run_fpga_tests || true
    fi
    
    if [ "$RUN_PERFORMANCE_TESTS" = true ]; then
        run_performance_tests || true
    fi
    
    # Generate coverage if requested
    if [ "$RUN_COVERAGE" = true ]; then
        generate_coverage
    fi
    
    # Print summary
    print_summary
    
    # Return appropriate exit code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
