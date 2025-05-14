package dev.emi.emi.api.render;

import dev.emi.emi.EmiRenderHelper;
import dev.emi.emi.api.stack.EmiIngredient;
import dev.emi.emi.runtime.EmiDrawContext;

public class EmiRender {
	
	public static void renderIngredientIcon(EmiIngredient ingredient, EmiDrawContext context, int x, int y) {
		EmiRenderHelper.renderIngredient(ingredient, context, x, y);
	}

	public static void renderTagIcon(EmiIngredient ingredient, EmiDrawContext context, int x, int y) {
		EmiRenderHelper.renderTag(ingredient, context, x, y);
	}

	public static void renderRemainderIcon(EmiIngredient ingredient, EmiDrawContext context, int x, int y) {
		EmiRenderHelper.renderRemainder(ingredient, context, x, y);
	}

	public static void renderCatalystIcon(EmiIngredient ingredient, EmiDrawContext context, int x, int y) {
		EmiRenderHelper.renderCatalyst(ingredient, context, x, y);
	}
}
