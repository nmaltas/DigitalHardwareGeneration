#ifndef PARAMETERS_HPP
#define PARAMETERS_HPP

#include <cstdint>
#include <vector>
#include <string>

using namespace std;

class Parameters
{
public:
    uint32_t M = 3; // Rows
    uint32_t N = 4; // Columns
    uint32_t T = 8; // Width [4,32]

    vector<vector<int_fast32_t>> WMatrix{
        {116, -121, 113, -125},
        {94, -107, -113, -99},
        {-116, 121, -113, 125},
    };

    vector<int_fast32_t> BMatrix{101, 83, -55};

    vector<int_fast32_t> XMatrix{-70, -17, -75, 3};

    string Libraries = "library IEEE;\nuse IEEE.STD_LOGIC_1164.all;\nuse ieee.numeric_std.all;";

    Parameters()
    {
        cout << "The system supports " << M << " x " << N << " operations of width " << T << "." << endl;
    }
};

#endif