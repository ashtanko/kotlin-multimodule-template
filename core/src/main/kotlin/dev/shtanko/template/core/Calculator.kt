/*
 * Copyright 2022 Oleksii Shtanko
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package dev.shtanko.template.core

import kotlin.math.ln
import kotlin.math.sqrt

/**
 * A calculator.
 *
 * This class just a documentation example.
 *
 * @constructor Creates an empty calculator.
 */
class Calculator {
    /**
     * Sums two integers.
     *
     * @param augend the number to add to
     * @param addend the number to add
     * @return the sum of [augend] and [addend]
     */
    fun add(augend: Int, addend: Int) = augend + addend

    /**
     * Divides one integer by another, keeping the fractional part.
     *
     * @param dividend the number to divide
     * @param divisor the number to divide by
     * @return the exact quotient as a [Double]
     * @throws DivideByZeroException if [divisor] is zero
     */
    fun divide(dividend: Int, divisor: Int): Double = if (divisor == 0) {
        throw DivideByZeroException(dividend)
    } else {
        dividend.toDouble() / divisor.toDouble()
    }

    /**
     * Multiplies an integer by itself.
     *
     * @param number the number to square
     * @return [number] multiplied by itself
     */
    fun square(number: Int) = number * number

    /**
     * Computes the non-negative square root of an integer.
     *
     * @param number the number to take the root of
     * @return the square root of [number], or `NaN` if it is negative
     */
    fun squareRoot(number: Int) = sqrt(number.toDouble())

    /**
     * Computes a logarithm in an arbitrary base.
     *
     * @param base the logarithm base
     * @param value the number whose logarithm is taken
     * @return the logarithm of [value] in [base]
     */
    fun log(base: Int, value: Int) = ln(value.toDouble()) / ln(base.toDouble())
}
