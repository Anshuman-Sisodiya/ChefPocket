package com.chefpocket.app.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.outlined.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.chefpocket.app.data.models.DietType
import com.chefpocket.app.data.models.Recipe
import com.chefpocket.app.data.models.RecipeScope
import com.chefpocket.app.ui.theme.*

// MARK: - FSSAI Food Safety Diet Badges
@Composable
fun FSSAIBadge(diet: DietType, size: Int = 16) {
    val isVeg = diet == DietType.VEG
    val borderColor = if (isVeg) VegGreen else NonVegRed

    Box(
        modifier = Modifier
            .size(size.dp)
            .clip(RoundedCornerShape(3.dp))
            .background(Color.White)
            .padding(1.5.dp),
        contentAlignment = Alignment.Center
    ) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            // Square border
            drawRect(color = borderColor, style = androidx.compose.ui.graphics.drawscope.Stroke(width = 1.5.dp.toPx()))

            if (isVeg) {
                // Circle inside
                drawCircle(color = borderColor, radius = this.size.minDimension / 3.2f)
            } else {
                // Triangle inside
                val path = Path().apply {
                    moveTo(this@Canvas.size.width / 2f, this@Canvas.size.height * 0.2f)
                    lineTo(this@Canvas.size.width * 0.8f, this@Canvas.size.height * 0.8f)
                    lineTo(this@Canvas.size.width * 0.2f, this@Canvas.size.height * 0.8f)
                    close()
                }
                drawPath(path, color = borderColor)
            }
        }
    }
}

// MARK: - Diet Pill Button
@Composable
fun DietPillButton(
    title: String,
    count: Int,
    isSelected: Boolean,
    dotColor: Color? = null,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(18.dp),
        color = if (isSelected) PrimaryOrange else MaterialTheme.colorScheme.surfaceVariant,
        contentColor = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.height(34.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            modifier = Modifier.padding(horizontal = 12.dp)
        ) {
            if (dotColor != null) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(if (isSelected) Color.White else dotColor)
                )
            }
            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
            )
            Text(
                text = "($count)",
                style = MaterialTheme.typography.labelSmall,
                color = if (isSelected) Color.White.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
    }
}

// MARK: - 3-Way Scope Segmented Button
@Composable
fun ScopeSegmentedControl(
    selectedScope: RecipeScope,
    curatedCount: Int,
    myKitchenCount: Int,
    favoritesCount: Int,
    onScopeSelected: (RecipeScope) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant)
            .padding(3.dp),
        horizontalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        // Curated
        ScopeSegmentItem(
            title = "Curated",
            count = curatedCount,
            icon = Icons.Default.MenuBook,
            isSelected = selectedScope == RecipeScope.CURATED,
            modifier = Modifier.weight(1f),
            onClick = { onScopeSelected(RecipeScope.CURATED) }
        )
        // Kitchen
        ScopeSegmentItem(
            title = "Kitchen",
            count = myKitchenCount,
            icon = Icons.Default.Restaurant,
            isSelected = selectedScope == RecipeScope.MY_KITCHEN,
            modifier = Modifier.weight(1f),
            onClick = { onScopeSelected(RecipeScope.MY_KITCHEN) }
        )
        // Favorites
        ScopeSegmentItem(
            title = "Favorites",
            count = favoritesCount,
            icon = Icons.Default.Favorite,
            iconTint = if (selectedScope == RecipeScope.FAVORITES) Color.White else Color.Red,
            isSelected = selectedScope == RecipeScope.FAVORITES,
            modifier = Modifier.weight(1f),
            onClick = { onScopeSelected(RecipeScope.FAVORITES) }
        )
    }
}

@Composable
private fun ScopeSegmentItem(
    title: String,
    count: Int,
    icon: ImageVector,
    iconTint: Color? = null,
    isSelected: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Surface(
        onClick = onClick,
        shape = RoundedCornerShape(11.dp),
        color = if (isSelected) PrimaryOrange else Color.Transparent,
        contentColor = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface,
        modifier = modifier
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint ?: (if (isSelected) Color.White else MaterialTheme.colorScheme.onSurfaceVariant),
                modifier = Modifier.size(14.dp)
            )
            Spacer(modifier = Modifier.width(4.dp))
            Text(
                text = title,
                fontSize = 12.sp,
                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
            )
            Spacer(modifier = Modifier.width(3.dp))
            Text(
                text = "($count)",
                fontSize = 10.sp,
                color = if (isSelected) Color.White.copy(alpha = 0.85f) else MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
            )
        }
    }
}

// MARK: - Macro Pill
@Composable
fun MacroPill(label: String, value: String, icon: ImageVector? = null, color: Color = PrimaryOrange) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(color.copy(alpha = 0.12f))
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        if (icon != null) {
            Icon(imageVector = icon, contentDescription = null, tint = color, modifier = Modifier.size(12.dp))
        }
        Text(text = label, fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(text = value, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = color)
    }
}

// MARK: - Recipe Card
@Composable
fun RecipeCard(
    recipe: Recipe,
    onClick: () -> Unit,
    onFavoriteToggle: () -> Unit
) {
    Card(
        onClick = onClick,
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 6.dp)
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Header: Badges & Favorite Heart
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FSSAIBadge(diet = recipe.dietType, size = 14)
                    Text(
                        text = recipe.cuisine,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    Text(text = "•", fontSize = 11.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        text = recipe.category,
                        fontSize = 11.sp,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                IconButton(
                    onClick = onFavoriteToggle,
                    modifier = Modifier.size(24.dp)
                ) {
                    Icon(
                        imageVector = if (recipe.isFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                        contentDescription = "Favorite",
                        tint = if (recipe.isFavorite) Color.Red else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            // Recipe Title
            Text(
                text = recipe.title,
                style = MaterialTheme.typography.titleMedium,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            // Macros & Whistle Count
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                MacroPill(label = "Protein", value = "${recipe.proteinGrams}g", color = PrimaryOrange)
                MacroPill(label = "Cal", value = "${recipe.calories}", color = AccentOrange)
                MacroPill(label = "Time", value = "${recipe.prepTimeMinutes}m", icon = Icons.Default.Schedule, color = MaterialTheme.colorScheme.primary)

                if (recipe.whistleCount != null) {
                    MacroPill(label = "Whistles", value = "${recipe.whistleCount}", color = Color(0xFF009688))
                }
            }
        }
    }
}
