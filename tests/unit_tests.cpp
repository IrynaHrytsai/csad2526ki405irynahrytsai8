#include <iostream>
#include "../math_operations.h"

int main() {
    // Simple test cases for add function
    if (add(2, 3) != 5) {
        std::cerr << "Test failed: add(2, 3) != 5" << std::endl;
        return 1;
    }
    if (add(-1, 1) != 0) {
        std::cerr << "Test failed: add(-1, 1) != 0" << std::endl;
        return 1;
    }
    if (add(0, 0) != 0) {
        std::cerr << "Test failed: add(0, 0) != 0" << std::endl;
        return 1;
    }
    std::cout << "All tests passed!" << std::endl;
    return 0;
}