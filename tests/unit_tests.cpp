#include <gtest/gtest.h>
#include "../math_operations.h"

TEST(AddTest, Positive) {
    EXPECT_EQ(add(2, 3), 5);
}

TEST(AddTest, Mixed) {
    EXPECT_EQ(add(-1, 1), 0);
}

TEST(AddTest, Zero) {
    EXPECT_EQ(add(0, 0), 0);
}